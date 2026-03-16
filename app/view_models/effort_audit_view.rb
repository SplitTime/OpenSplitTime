class EffortAuditView < EffortWithLapSplitRows
  delegate :event_name, :person, :start_time, :start_time?, :stopped?, to: :effort
  delegate :simple?, :multiple_sub_splits?, :laps_unlimited?, :event_group, to: :event

  def audit_rows
    lap_splits.flat_map do |lap_split|
      lap_split.bitkeys.map do |bitkey|
        time_point = lap_split.time_point(bitkey)
        split_time = indexed_split_times[time_point] || effort.split_times.new(time_point: time_point)
        matched_raw_times = raw_times.select { |rt| matched?(rt, split_time) }
        unmatched_raw_times = raw_times.select { |rt| associated_but_unmatched?(rt, time_point) }
        disassociated_raw_times = raw_times.select { |rt| disassociated?(rt, time_point) }

        EffortAuditRow.new(lap_split: lap_split, bitkey: bitkey, split_time: split_time, home_time_zone: home_time_zone,
                           matched_raw_times: matched_raw_times, unmatched_raw_times: unmatched_raw_times,
                           disassociated_raw_times: disassociated_raw_times)
      end
    end
  end

  def raw_times_count
    raw_times.size
  end

  def rebuildable?
    raw_times_count.positive? && multiple_laps?
  end

  private

  def raw_times
    return [] if effort.bib_number.blank?

    @raw_times ||=
      begin
        result = event_group.raw_times.where(matchable_bib_number: effort.bib_number).with_relation_ids
        result.each { |rt| rt.lap ||= 1 }
        result
      end
  end

  def matched?(raw_time, split_time)
    raw_time.split_time_id && raw_time.split_time_id == split_time.id
  end

  def associated_but_unmatched?(raw_time, time_point)
    raw_time.split_time_id.nil? && raw_time.time_point == time_point && !raw_time.disassociated_from_effort
  end

  def disassociated?(raw_time, time_point)
    raw_time.split_time_id.nil? && raw_time.time_point == time_point && raw_time.disassociated_from_effort
  end
end
