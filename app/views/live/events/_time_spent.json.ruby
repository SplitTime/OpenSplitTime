effort = Effort.where(id: params[:effortId]).first
time_from_start_in = params[:timeFromStartIn].present? ? params[:timeFromStartIn] : nil
subject_split = Split.where(id: params[:splitId]).first
day_and_time = (effort && subject_split) ? effort.likely_intended_time(params[:timeOut], subject_split) :nil
time_from_start_out = (effort && day_and_time) ? day_and_time - effort.start_time : nil
time_in_aid = (time_from_start_out && time_from_start_in) ? time_from_start_out - time_from_start_in : nil

{
    success: time_in_aid ? true : false,
    timeInAid: time_format_minutes(time_in_aid),
    timeFromStartOut: time_from_start_out
}.to_json