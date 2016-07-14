effort_data_object = LiveEffortData.new(@event, params)
last_split = effort_data_object.last_split
dropped_split = effort_data_object.dropped_split
report_text = case
                when effort_data_object.effort.nil?
                  'n/a'
                when effort_data_object.finished
                  last_split ? "Finished as of #{l(effort_data_object.last_day_and_time, format: :day_and_military)}" : nil
                when !effort_data_object.started
                  'Not yet started'
                else
                  last_split ? "#{last_split.name(effort_data_object.last_bitkey)} • #{l(effort_data_object.last_day_and_time, format: :day_and_military)}" : nil
              end
if effort_data_object.dropped
  dropped_text = (dropped_split == last_split) ?
      ' and dropped there' :
      " but reported dropped at #{dropped_split.base_name} • #{l(effort_data_object.dropped_day_and_time, format: :day_and_military)}"
  report_text.concat(dropped_text)
end

prior_valid_report_text = (effort_data_object.effort && effort_data_object.prior_valid_split) ?
    "#{effort_data_object.prior_valid_split.name(effort_data_object.prior_valid_bitkey)} • #{l(effort_data_object.prior_valid_day_and_time, format: :day_and_military)}" : 'n/a'

{
    effortId: effort_data_object.effort_id,
    name: effort_data_object.effort_name,
    reportText: report_text,
    priorValidReportText: prior_valid_report_text,
    timeFromPriorValid: time_format_hhmm(effort_data_object.time_from_prior_valid),
    timeInAid: "#{time_format_minutes(effort_data_object.time_in_aid)} minutes",
    timeInExists: effort_data_object.time_in_exists,
    timeOutExists: effort_data_object.time_out_exists,
    timeInStatus: effort_data_object.time_in_status,
    timeOutStatus: effort_data_object.time_out_status,
    splitDistance: effort_data_object.split_distance

}.to_json
