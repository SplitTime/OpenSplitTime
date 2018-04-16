# frozen_string_literal: true

class TimeRecordPairer
  def self.pair(args)
    new(args).pair
  end

  def initialize(args)
    @event = args[:event]
    @time_records = args[:time_records]
    @pairer = args[:pairer] || ObjectPairer
    validate_setup
  end

  def pair
    time_record_pairs.reject(&:blank?).flatten(1)
  end

  private

  attr_reader :event, :time_records, :pairer

  def time_record_pairs
    @time_record_pairs ||= split_pairs.map { |split_pair| pairer.pair(objects: time_records,
                                                                      identical_attributes: :bib_number,
                                                                      pairing_criteria: split_pair) }
  end

  def split_pairs
    @split_pairs ||= event.live_entry_attributes.map { |element| [split_and_bitkey(element[:entries].first),
                                                                  split_and_bitkey(element[:entries].second)] }
  end

  def split_and_bitkey(entry)
    entry ||= {}
    {split_id: entry[:split_id], bitkey: SubSplit.bitkey(entry[:sub_split_kind])}
  end

  def split_ids
    @split_ids ||= split_pairs.flat_map { |split_pair| [split_pair.first[:split_id], split_pair.second[:split_id]] }
                       .compact.to_set
  end

  def validate_setup
    raise ArgumentError, 'All time_records must match the provided event' unless time_records.all? { |lt| lt.event_id == event.id }
    raise ArgumentError, 'All time_records must match the splits available within live_entry_attributes' unless time_records.all? { |lt| split_ids.include?(lt.split_id) }
  end
end
