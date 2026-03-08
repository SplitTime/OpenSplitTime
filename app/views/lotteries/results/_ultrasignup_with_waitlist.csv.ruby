require "csv"

if records.present?
  ::CSV.generate do |csv|
    csv << [
      "Order ID",
      "First name",
      "Last name",
      "Gender",
      "Birthdate",
      "Status",
    ]
    records.each do |row|
      csv << [
        row.external_id,
        row.first_name,
        row.last_name,
        row.gender,
        row.birthdate,
        row.draw_status,
      ]
    end
  end
else
  "No records to export."
end
