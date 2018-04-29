CSV.generate do |csv|
  csv << %w(Bib Finish Combined)
  if @presenter.finish_live_times.present?
    @presenter.finish_live_times.find_each do |lt|
      time = "#{lt.military_time(lt.event.home_time_zone)}.0"
      csv << [lt.bib_number, time, "#{time} (#{lt.bib_number})"]
    end
  else
    csv << ['No finish live times are available.']
  end
end
