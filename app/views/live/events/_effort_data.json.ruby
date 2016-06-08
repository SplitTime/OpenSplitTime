effort = @event.efforts.find_by_bib_number(params[:bibNumber])
last_split_time = effort ? effort.last_reported_split_time : nil
last_split = last_split_time ? last_split_time.split : nil
bitkey = last_split_time ? last_split_time.sub_split_bitkey : nil
if effort.nil?
  report_text = "Bib number was not located"
elsif effort.dropped?
  report_text = last_split ? "Dropped at #{last_split.base_name} as of #{l(last_split_time.day_and_time, format: :day_and_military)}" : nil
elsif effort.finished?
  report_text = last_split ? "Finished as of #{l(last_split_time.day_and_time, format: :day_and_military)}" : nil
else
  report_text = last_split ? "#{last_split.name(bitkey)} • #{l(last_split_time.day_and_time, format: :day_and_military)}" : nil
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