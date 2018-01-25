CSV.generate do |csv|
  csv << plan_export_headers
  @plan_display.lap_split_rows.each do |row|
    csv << lap_split_export_row(row)
  end
end
