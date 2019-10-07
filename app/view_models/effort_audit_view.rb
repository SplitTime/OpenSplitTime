# frozen_string_literal: true

class EffortAuditView < EffortWithLapSplitRows

  delegate :event_name, :person, :start_time, :has_start_time?, :stopped?, to: :loaded_effort
  delegate :simple?, :multiple_sub_splits?, :multiple_laps?, :laps_unlimited?, :event_group, to: :event

  def audit_rows
    name_method = multiple_laps? ? :name : :name_without_lap

    lap_splits.flat_map do |lap_split|
      lap_split.bitkeys.map do |bitkey|
        time_point = lap_split.time_point(bitkey)
        split_time = split_times.find { |st| st.time_point == time_point }
        OpenStruct.new(name: lap_split.public_send(name_method, bitkey),
                       time_point: time_point,
                       split_time: split_time,
                       matched_raw_times: raw_times.select { |rt| rt.split_time_id && rt.split_time_id == split_time&.id },
                       unmatched_raw_times: raw_times.select { |rt| rt.split_time_id.nil? && rt.time_point == split_time.time_point })
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
