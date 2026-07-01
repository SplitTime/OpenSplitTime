# Testing tool: duplicates an event group and populates each event with `count` fabricated-identity
# runners whose split times are real progressions from a past run, truncated at `cutoff_time` and
# shifted so that cutoff lands at `current_time` — producing a live, in-progress event group.
#
# Unlike DuplicateEventGroup (structure only, current-year-from-past-year), this copies efforts + times.
class SimulateInProgressEventGroup
  def self.perform(**)
    new(**).perform
  end

  def initialize(source_event_group:, cutoff_time:, count:, current_time: Time.current)
    @source_event_group = source_event_group
    @cutoff_time = cutoff_time
    @count = count
    @current_time = current_time
    @simulated_efforts_count = 0
  end

  attr_reader :new_event_group, :simulated_efforts_count

  def perform
    ActiveRecord::Base.transaction do
      build_event_group
      new_event_group.save!
      conform_splits
      populate_efforts
    end
    self
  end

  private

  attr_reader :source_event_group, :cutoff_time, :count, :current_time, :event_pairs

  # Seconds to add to every source time so the cutoff moment maps to now.
  def offset
    @offset ||= current_time - cutoff_time
  end

  def build_event_group
    @new_event_group = source_event_group.dup
    new_event_group.assign_attributes(
      name: "#{source_event_group.name} (Simulated #{current_time.strftime('%Y-%m-%d %H:%M')})",
      concealed: true,
      available_live: true,
      webhook_token: nil,
    )
    @event_pairs = source_event_group.events.map do |source_event|
      new_event = source_event.dup
      new_event.assign_attributes(
        scheduled_start_time: source_event.scheduled_start_time + offset,
        historical_name: nil,
        beacon_url: nil,
        efforts_count: 0,
        topic_resource_key: nil,
      )
      new_event_group.events << new_event
      [source_event, new_event]
    end
  end

  # Saving the events attaches all course splits to each, so prune those not in the source event.
  def conform_splits
    event_pairs.each do |source_event, new_event|
      new_event.aid_stations.each do |aid_station|
        aid_station.destroy unless aid_station.split_id.in?(source_event.split_ids)
      end
    end
  end

  def populate_efforts
    bib_number = 1
    event_pairs.each do |source_event, new_event|
      started_source_efforts(source_event).sample(count).each do |source_effort|
        create_simulated_effort(new_event, source_effort, bib_number)
        bib_number += 1
      end
    end
  end

  # Source efforts that had recorded their start on or before the cutoff (i.e. in progress at that moment).
  def started_source_efforts(source_event)
    source_event.efforts.includes(split_times: :split).select do |effort|
      earliest = effort.split_times.map(&:absolute_time).min
      earliest.present? && earliest <= cutoff_time
    end
  end

  def create_simulated_effort(new_event, source_effort, bib_number)
    attributes = RandomEffortAttributes.generate.merge(bib_number: bib_number)
    if source_effort.scheduled_start_time
      attributes[:scheduled_start_time] = source_effort.scheduled_start_time + offset
    end

    effort = new_event.efforts.new(attributes)
    source_effort.split_times.select { |split_time| split_time.absolute_time <= cutoff_time }.each do |split_time|
      effort.split_times.new(
        split_id: split_time.split_id,
        lap: split_time.lap,
        sub_split_bitkey: split_time.sub_split_bitkey,
        absolute_time: split_time.absolute_time + offset,
        stopped_here: split_time.stopped_here,
        pacer: split_time.pacer,
      )
    end

    effort.save!
    Results::SetEffortPerformanceData.perform!(effort.id)
    @simulated_efforts_count += 1
  end
end
