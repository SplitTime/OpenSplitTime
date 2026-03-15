require "csv"

::CSV.generate do |csv|
  csv << plan_export_headers(@presenter)
  @presenter.lap_split_rows.each do |row|
    csv << lap_split_export_row(@presenter, row)
  end
end
