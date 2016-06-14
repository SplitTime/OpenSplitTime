response = LiveEffortData.new(@event, params)
last_split = response.last_split
report_text = case
                  when response.effort.nil?
                      'Bib number was not located'
                  when response.dropped
                      last_split ? "Dropped at #{last_split.base_name} as of #{l(response.last_day_and_time, format: :day_and_military)}" : nil
                  when response.finished
                      last_split ? "Finished as of #{l(response.last_day_and_time, format: :day_and_military)}" : nil
                  else
                      last_split ? "#{last_split.name(response.last_bitkey)} • #{l(response.last_day_and_time, format: :day_and_military)}" : nil
              end

prior_valid_report_text = response.effort.nil? ? '' : "#{response.prior_valid_split.name(response.prior_valid_bitkey)} • #{l(response.prior_valid_day_and_time, format: :day_and_military)}"

{
        success: response.success?,
        effortId: response.effort_id,
        name: response.effort_name,
        reportText: report_text,
        priorValidReportText: prior_valid_report_text,
        dropped: response.dropped,
        finished: response.finished,
        timeFromLastValid: time_format_hhmm(response.time_from_last_valid),
        timeInAid: "#{time_format_minutes(response.time_in_aid)} minutes",
        timeFromStartIn: response.time_from_start_in,
        timeFromStartOut: response.time_from_start_out,
        timeInExists: response.time_in_exists,
        timeOutExists: response.time_out_exists,
        timeInStatus: response.time_in_status,
        timeOutStatus: response.time_out_status

}.to_json
