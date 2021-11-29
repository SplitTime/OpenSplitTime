# frozen_string_literal: true

class RawTimePairer
  def self.pair(args)
    new(args).pair
  end

  def initialize(args)
    @event_group = args[:event_group]
    @raw_times = args[:raw_times]
    @pairer = args[:pairer] || ObjectPairer
    validate_setup
  end

  def pair
    pairer.pair(objects: raw_times,
                identical_attributes: [:bib_number, :lap, :parameterized_split_name],
                pairing_criteria: [{bitkey: 1}, {bitkey: 64}])
  end

  private

  attr_reader :event_group, :raw_times, :pairer

  def validate_setup
    raise ArgumentError, 'All raw_times must match the provided event_group' unless raw_times.all? { |rt| rt.event_group_id == event_group.id }
  end
end
