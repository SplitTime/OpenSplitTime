effort = Effort.find(params[:effortId])
last_split_time = effort ?
    effort.split_times.where(split_id: params[:lastReportedSplitId],
                             sub_split_bitkey: params[:lastReportedBitkey]).first : nil
subject_split = Split.where(id: params[:splitId]).first
day_and_time = (effort && subject_split) ? effort.likely_intended_time(params[:timeIn], subject_split) : nil
time_from_start = (effort && day_and_time) ? day_and_time - effort.start_time : nil
time_from_last = (time_from_start && last_split_time) ? time_from_start - last_split_time.time_from_start : nil

{
    success: time_from_last ? true : false,
    timeFromLastReported: time_format_hhmm(time_from_last),
    timeFromStartIn: time_from_start
}.to_json