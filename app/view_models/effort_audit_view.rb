# frozen_string_literal: true

class EffortAuditView < EffortWithLapSplitRows

  DISCREPANCY_THRESHOLD = 1.minute

  delegate :event_name, :person, :start_time, :has_start_time?, :stopped?, to: :loaded_effort
  delegate :simple?, :multiple_sub_splits?, :multiple_laps?, :laps_unlimited?, :event_group, to: :event

  def audit_rows
    name_method = multiple_laps? ? :name : :name_without_lap

    lap_splits.flat_map do |lap_split|
      lap_split.bitkeys.map do |bitkey|
        time_point = lap_split.time_point(bitkey)
        split_time = indexed_split_times[time_point] || effort.split_times.new(time_point: time_point)
        matched_raw_times = raw_times.select { |rt| rt.split_time_id && rt.split_time_id == split_time.id }
        unmatched_raw_times = raw_times.select { |rt| rt.split_time_id.nil? && rt.time_point == time_point }

        OpenStruct.new(name: lap_split.public_send(name_method, bitkey),
                       parameterized_split_name: lap_split.split.parameterized_base_name,
                       sub_split_kind: SubSplit.kind(bitkey).downcase,
                       time_point: time_point,
                       split_time: split_time,
                       matched_raw_times: matched_raw_times,
                       unmatched_raw_times: unmatched_raw_times,
                       problem: problem?(split_time, matched_raw_times + unmatched_raw_times))
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

  def problem?(split_time, raw_times)
    joined_military_times = (raw_times.map { |rt| rt.military_time(home_time_zone) } + [split_time.military_time]).compact.sort
    return false unless joined_military_times.present?

    times_in_seconds = joined_military_times.map { |military_time| TimeConversion.hms_to_seconds(military_time) }
    adjusted_times = times_in_seconds.map { |seconds| (seconds - times_in_seconds.first) > 12.hours ? (seconds - 24.hours).to_i : seconds }.sort
    largest_discrepancy = (adjusted_times.last - adjusted_times.first).to_i

    single_lap? && largest_discrepancy > DISCREPANCY_THRESHOLD
  end

  def single_lap?
    !multiple_laps?
  end
end
