effort = Effort.find(params[:effortId])
time_from_start_in = params[:timeFromStartIn].to_f
subject_split = Split.find(params[:splitId])
day_and_time = (effort && subject_split) ? effort.likely_intended_time(params[:timeOut], subject_split) :nil
time_from_start_out = day_and_time ? day_and_time - effort.start_time : nil
time_in_aid = time_from_start_out - time_from_start_in

{
    success: time_in_aid ? true : false,
    timeInAid: time_format_minutes(time_in_aid),
    timeFromStartOut: time_from_start_out
}.to_json