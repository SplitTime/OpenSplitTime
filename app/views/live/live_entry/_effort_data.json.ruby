effort = @event.efforts.where(bib_number: params[:bibNumber].to_i).first
last_split_time = effort ? effort.last_reported_split_time : nil
last_split = last_split_time ? last_split_time.split : nil
bitkey = last_split_time ? last_split_time.sub_split_bitkey : nil
if effort.dropped?
    report_text = last_split ? "Dropped at #{last_split.base_name} as of #{day_time_format(last_split_time.day_and_time)}" : nil
elsif effort.finished?
    report_text = last_split ? "Finished as of #{day_time_format(last_split_time.day_and_time)}" : nil
else
    report_text = last_split ? "#{last_split.name(bitkey)} • #{day_time_format(last_split_time.day_and_time)}" : nil
end

{
        success: effort ? true : false,
        effortId: effort ? effort.id : nil,
        name: effort ? effort.full_name : nil,
        lastReportedSplitId: last_split ? last_split.id : nil,
        lastReportedBitkey: bitkey ? bitkey : nil,
        reportText: last_split ? report_text : nil,
        dropped: effort ? effort.dropped? : nil,
        finished: effort ? effort.finished? : nil
}.to_json