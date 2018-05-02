CSV.generate do |csv|
  csv << %w(Bib Finish Combined)
  if @presenter.finish_live_times.present?
    @presenter.finish_live_times.sort_by { |lt| lt.military_time(lt.event.home_time_zone) }.each do |lt|
      time = "#{lt.military_time(lt.event.home_time_zone)}"
      csv << [lt.bib_number, time, "#{time} (#{lt.bib_number})"]
    end
  else
    csv << ['No finish live times are available.']
  end
end
