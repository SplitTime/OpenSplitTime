# frozen_string_literal: true

if records.present?
  CSV.generate do |csv|
    csv << [
      "Order ID",
      "First name",
      "Last name",
      "Gender",
      "Birthdate",
    ]
    records.each do |row|
      csv << [
        row.external_id,
        row.first_name,
        row.last_name,
        row.gender,
        row.birthdate,
      ]
    end
  end
else
  "No records to export."
end
