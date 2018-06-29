# frozen_string_literal: true

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
    @raw_time_pair = args[:raw_time_row].raw_times
    @times_container = args[:times_container] || SegmentTimesContainer.new(calc_model: :stats)
    @errors = []
  end

  def perform
    add_lap_to_raw_times
    build_time_row(raw_time_pair)
  end

  private

  attr_reader :event_group, :raw_time_pair, :times_container, :errors

  def add_lap_to_raw_times
    raw_time_pair.reject(&:lap).each do |raw_time|
      if single_lap_event_group? || single_lap_event?
        raw_time.lap = 1
      elsif effort.nil?
        raw_time.lap = nil
      elsif raw_time.absolute_time
        raw_time.lap = expected_lap(raw_time, :day_and_time, raw_time.absolute_time)
      else
        raw_time.lap = expected_lap(raw_time, :military_time, raw_time.military_time)
      end
    end
  end

  def expected_lap(raw_time, subject_attribute, subject_value)
    FindExpectedLap.perform(effort: effort,
                            subject_attribute: subject_attribute,
                            subject_value: subject_value,
                            split_id: split&.id,
                            bitkey: raw_time.bitkey)
  end

  def build_time_row(raw_time_pair)
    raw_time_pair.each { |rtr| rtr.effort, rtr.event, rtr.split = effort, event, split }
    raw_time_row = RawTimeRow.new(raw_time_pair, effort, event, split, errors)
    VerifyRawTimeRow.perform(raw_time_row, times_container: times_container)
    raw_time_row
  end

  def single_lap_event_group?
    @single_lap_event_group ||= event_group.single_lap?
  end

  def single_lap_event?
    event&.single_lap?
  end

  def effort
    @effort ||= Effort.where(event: event_group.events, bib_number: bib_number).includes(event: :splits, split_times: :split).first
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
