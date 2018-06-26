CSV.generate do |csv|
  csv << %w(Bib Kind Time Combined)
  if @raw_times.present?
    @raw_times.sort_by { |rt| rt.military_time(rt.event_group.home_time_zone) }.each do |rt|
      time = "#{rt.military_time(rt.event_group.home_time_zone)}"
      csv << [rt.bib_number, rt.sub_split_kind, time, "#{time} (#{rt.bib_number})"]
    end
  else
    csv << ['No raw times were located.']
  end
end
