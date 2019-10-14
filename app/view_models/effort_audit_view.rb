# frozen_string_literal: true

class EffortAuditView < EffortWithLapSplitRows

  DISCREPANCY_THRESHOLD = 1.minute

  delegate :event_name, :person, :start_time, :has_start_time?, :stopped?, to: :loaded_effort
  delegate :simple?, :multiple_sub_splits?, :laps_unlimited?, :event_group, to: :event

  def audit_rows
    lap_splits.flat_map do |lap_split|
      lap_split.bitkeys.map do |bitkey|
        time_point = lap_split.time_point(bitkey)
        split_time = indexed_split_times[time_point] || effort.split_times.new(time_point: time_point)
        matched_raw_times = raw_times.select { |rt| rt.split_time_id && rt.split_time_id == split_time.id }
        unmatched_raw_times = raw_times.select { |rt| rt.split_time_id.nil? && rt.time_point == time_point }

        EffortAuditRow.new(lap_split: lap_split, bitkey: bitkey, split_time: split_time, home_time_zone: home_time_zone,
                           matched_raw_times: matched_raw_times, unmatched_raw_times: unmatched_raw_times)
      end
    end
  end

  private

  def raw_times
    @raw_times ||=
      begin
        result = event_group.raw_times.where(bib_number: effort.bib_number).with_relation_ids
        result.each { |rt| rt.lap ||= 1 }
        result
      end
  end
end
