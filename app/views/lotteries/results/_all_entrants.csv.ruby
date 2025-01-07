require "csv"

if records.present?
  ::CSV.generate do |csv|
    csv << [
      "First name",
      "Last name",
      "Gender",
      "Birthdate",
      "Email",
      "Ticket count",
      "Status",
    ]
    records.each do |row|
      csv << [
        row.first_name,
        row.last_name,
        row.gender.titleize,
        row.birthdate,
        row.email,
        row.number_of_tickets,
        row.draw_status.titleize,
      ]
    end
  end
else
  "No records to export."
end
