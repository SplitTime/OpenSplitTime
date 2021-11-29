# frozen_string_literal: true

# event_group should be loaded with :events
# raw_time_row may be a bare minimum raw_time without any attributes
# This service mutates the given raw_time_row by adding laps, fixing problems with stopped_here,
# and verifying the raw_time_row

class EnrichRawTimeRow
  def self.perform(args)
    new(args).perform
  end

  def initialize(args)
    ArgsValidator.validate(params: args,
                           required: [:event_group, :raw_time_row],
                           exclusive: [:event_group, :raw_time_row, :times_container],
                           class: self.class)
    @event_group = args[:event_group]
    @raw_time_row = args[:raw_time_row]
    @times_container = args[:times_container] || SegmentTimesContainer.new(calc_model: :stats)
    @errors = []
  end

  def perform
    add_lap_to_raw_times
    remove_enriched_attributes
    set_stops
    add_attributes_and_verify
    raw_time_row
  end

  private

  attr_reader :event_group, :raw_time_row, :times_container, :errors

  def add_lap_to_raw_times
    raw_time_pair.reject(&:lap).each do |raw_time|
      if single_lap_event_group? || single_lap_event?
        raw_time.lap = 1
      elsif effort.nil? || split.nil?
        raw_time.lap = nil
      elsif raw_time.absolute_time
        raw_time.lap = expected_lap(raw_time, :absolute_time, raw_time.absolute_time)
      elsif raw_time.military_time
        raw_time.lap = expected_lap(raw_time, :military_time, raw_time.military_time)
      else
        raw_time.lap = nil
      end
    end
  end

  def expected_lap(raw_time, subject_attribute, subject_value)
    FindExpectedLap.perform(effort: effort,
                            subject_attribute: subject_attribute,
                            subject_value: subject_value,
                            split_id: split.id,
                            bitkey: raw_time.bitkey)
  end

  def remove_enriched_attributes
    raw_time_pair.each do |raw_time|
      raw_time.assign_attributes(data_status: nil, split_time_exists: nil)
    end
  end

  def set_stops
    return unless raw_time_pair.any?(&:stopped_here)
    raw_time_pair.each { |raw_time| raw_time.stopped_here = false }
    raw_time_pair.select(&:has_time_data?).last&.assign_attributes(stopped_here: true)
  end

  def add_attributes_and_verify
    raw_time_pair.each { |raw_time| raw_time.effort, raw_time.event, raw_time.split = effort, event, split }
    raw_time_row.effort, raw_time_row.event, raw_time_row.split = effort, event, split
    raw_time_row.errors ||= []
    raw_time_row.errors += errors
    VerifyRawTimeRow.perform(raw_time_row, times_container: times_container)
  end

  def single_lap_event_group?
    @single_lap_event_group ||= event_group.single_lap?
  end

  def single_lap_event?
    event&.single_lap?
  end

  def raw_time_pair
    @raw_time_pair ||= raw_time_row.raw_times
  end

  def effort
    return @effort if defined?(@effort)
    @effort = raw_time_row.effort || Effort.where(event: event_group.events, bib_number: bib_number)
                                         .includes(event: :splits, split_times: :split).first
  end

  def event
    @event ||= effort&.event
  end

  def split
    @split ||= event&.splits&.find { |split| split.parameterized_base_name == parameterized_split_name }
  end

  def bib_number
    raw_bib = raw_time_pair.first.bib_number
    raw_bib =~ /\D/ ? nil : raw_bib.to_i
  end

  def parameterized_split_name
    raw_time_pair.first&.split_name&.parameterize
  end
end
