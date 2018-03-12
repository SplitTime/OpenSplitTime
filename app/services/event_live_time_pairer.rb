# frozen_string_literal: true

class EventLiveTimePairer

  def self.pair(args)
    new(args).pair
  end

  def initialize(args)
    @event = args[:event]
    @live_times = args[:live_times]
    @pairer = args[:pairer] || ObjectPairer
    validate_setup
  end

  def pair
    live_time_pairs.reject(&:blank?).flatten(1)
  end

  private

  attr_reader :event, :live_times, :pairer

  def live_time_pairs
    @live_time_pairs ||= split_pairs.map { |split_pair| pairer.pair(objects: live_times,
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
    raise ArgumentError, 'All live_times must match the provided event' unless
        live_times.all? { |lt| lt.event_id == event.id }
    raise ArgumentError, 'All live_times must match the splits available within live_entry_attributes' unless
        live_times.all? { |lt| split_ids.include?(lt.split_id) }
  end
end
