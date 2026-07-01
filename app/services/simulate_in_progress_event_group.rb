# Testing tool: duplicates an event group and stages it as an in-progress race. Reuses
# DuplicateEventGroup for the structure copy, then shifts the duplicate's group start to
# `start_time` and populates each event with `effort_count` runners frozen at their position
# `elapsed_seconds` into the race — fabricated identities but real split-time progressions from a
# past run, truncated at the elapsed cutoff and shifted onto the new start.
class SimulateInProgressEventGroup
  def self.perform(**)
    new(**).perform
  end

  def initialize(source_event_group:, start_time:, elapsed_seconds:, effort_count:)
    @source_event_group = source_event_group
    @start_time = start_time
    @elapsed_seconds = elapsed_seconds
    @effort_count = effort_count
    @simulated_efforts_count = 0
  end

  attr_reader :new_event_group, :simulated_efforts_count

  def perform
    ActiveRecord::Base.transaction do
      build_event_group
      populate_efforts
    end
    self
  end

  private

  attr_reader :source_event_group, :start_time, :elapsed_seconds, :effort_count

  # Seconds to add to every source time so the source group's start lands at the requested start_time.
  def offset
    @offset ||= start_time - source_event_group.scheduled_start_time
  end

  # The simulated "current moment", in source terms: `elapsed_seconds` into the race from the group start.
  def source_cutoff
    @source_cutoff ||= source_event_group.scheduled_start_time + elapsed_seconds
  end

  # Reuse DuplicateEventGroup for the structure copy (group + events + conformed splits), then place the
  # duplicate's start exactly at start_time (DuplicateEventGroup only offsets by whole days) and enable live.
  def build_event_group
    duplicate = DuplicateEventGroup.create(existing_id: source_event_group.id,
                                           new_name: "#{source_event_group.name} (Simulated)",
                                           new_start_date: start_time.to_date)
    @new_event_group = duplicate.new_event_group
    unless new_event_group&.persisted?
      raise "Could not duplicate event group: #{duplicate.errors.full_messages.to_sentence}"
    end

    shift = start_time - new_event_group.scheduled_start_time
    new_event_group.events.each { |event| event.update!(scheduled_start_time: event.scheduled_start_time + shift) }
    new_event_group.update!(available_live: true)
  end

  def populate_efforts
    bib_number = 1
    event_pairs.each do |source_event, new_event|
      started_source_efforts(source_event).sample(effort_count).each do |source_effort|
        create_simulated_effort(new_event, source_effort, bib_number)
        bib_number += 1
      end
    end
  end

  def event_pairs
    new_event_group.events.map do |new_event|
      [source_event_group.events.find { |source_event| source_event.short_name == new_event.short_name }, new_event]
    end
  end

  # Source efforts that had recorded their start on or before the cutoff (in progress at that moment).
  def started_source_efforts(source_event)
    source_event.efforts.includes(split_times: :split).select do |effort|
      earliest = effort.split_times.map(&:absolute_time).min
      earliest.present? && earliest <= source_cutoff
    end
  end

  def create_simulated_effort(new_event, source_effort, bib_number)
    attributes = RandomEffortAttributes.generate.merge(bib_number: bib_number)
    if source_effort.scheduled_start_time
      attributes[:scheduled_start_time] = source_effort.scheduled_start_time + offset
    end

    effort = new_event.efforts.new(attributes)
    source_effort.split_times.select { |split_time| split_time.absolute_time <= source_cutoff }.each do |split_time|
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
