effort = Effort.find(params[:effortId])
last_split_time = effort ?
        effort.split_times.where(split_id: params[:lastReportedSplitId],
                                 sub_split_bitkey: params[:lastReportedBitkey].to_i).first : nil
subject_split = Split.find(params[:splitId])
time_from_last = (last_split_time && subject_split) ? (effort.likely_intended_time(params[:timeIn], subject_split) -
        effort.start_time -
        last_split_time.time_from_start) :
        nil

{
        success: time_from_last ? true : false,
        timeFromLastReported: time_from_last
}.to_json