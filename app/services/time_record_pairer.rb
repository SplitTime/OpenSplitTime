# frozen_string_literal: true

class TimeRecordPairer
  def self.pair(args)
    new(args).pair
  end

  def initialize(args)
    @time_records = args[:time_records]
    @pairer = args[:pairer] || ObjectPairer
  end

  def pair
    time_record_pairs.reject(&:blank?)
  end

  private

  attr_reader :time_records, :pairer

  def time_record_pairs
    @time_record_pairs ||= pairer.pair(objects: time_records,
                                       identical_attributes: [:event_id, :bib_number, :lap, :split_id],
                                       pairing_criteria: [{bitkey: 1}, {bitkey: 64}])
  end
end
