effort = Effort.find(params[:effortId])
last_split_time = effort ?
    effort.split_times.where(split_id: params[:lastReportedSplitId],
                             sub_split_bitkey: params[:lastReportedBitkey].to_i).first : nil
subject_split = Split.find(params[:splitId])
intended_day_and_time = (effort && subject_split) ? effort.likely_intended_time(params[:timeIn], subject_split) :nil
intended_time_from_start = intended_day_and_time ? intended_day_and_time - effort.start_time : nil
time_from_last = last_split_time ? intended_time_from_start - last_split_time.time_from_start : nil

{
    success: time_from_last ? true : false,
    timeFromLastReported: time_from_last,
    timeFromStart: intended_time_from_start
}.to_json