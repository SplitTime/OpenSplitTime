# frozen_string_literal: true

class EffortAuditView < EffortWithLapSplitRows

  delegate :event_name, :person, :start_time, :has_start_time?, :stopped?, to: :loaded_effort
  delegate :simple?, :multiple_sub_splits?, :multiple_laps?, :laps_unlimited?, :event_group, to: :event

  def audit_rows
    lap_splits.flat_map do |lap_split|
      lap_split.bitkeys.map do |bitkey|
        OpenStruct.new(name: lap_split.name(bitkey), time_point: lap_split.time_point(bitkey))
      end
    end
  end
end
