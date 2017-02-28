CSV.generate do |csv|
  csv << spread_export_headers
  @spread_display.effort_times_rows.each do |row|
    csv << time_row_export_row(row)
  end
end