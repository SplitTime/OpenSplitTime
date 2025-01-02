require "csv"

if records.present?
  ::CSV.generate do |csv|
    csv << [
      "First name",
      "Last name",
      "Gender",
      "Birthdate",
      "Email",
      "Status",
    ]
    records.each do |row|
      csv << [
        row.first_name,
        row.last_name,
        row.gender,
        row.birthdate,
        row.email,
        row.draw_status.titleize,
      ]
    end
  end
else
  "No records to export."
end
