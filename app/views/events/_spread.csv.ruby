CSV.generate do |csv|
  csv << @spread_display.export_headers
  @spread_display.effort_times_rows.each do |row|
    csv << row.export_row
  end
end