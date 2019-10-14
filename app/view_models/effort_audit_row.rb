# frozen_string_literal: true

EffortAuditRow = Struct.new(
  :name,
  :parameterized_split_name,
  :sub_split_kind,
  :time_point,
  :split_time,
  :matched_raw_times,
  :unmatched_raw_times,
  :problem,
  keyword_init: true
) do

end
