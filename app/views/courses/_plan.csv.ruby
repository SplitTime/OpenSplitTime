CSV.generate do |csv|
  csv << plan_export_headers
  @presenter.lap_split_rows.each do |row|
    csv << lap_split_export_row(row)
  end
end
