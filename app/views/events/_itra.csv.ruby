require "csv"

if records.present?
  ::CSV.generate do |csv|
    csv << [
      "Ranking",
      "Time",
      "Family Name",
      "First Name",
      "Gender",
      "Birthdate",
      "Nationality",
      "Bib no.",
      "City",
    ]

    records.each do |record|
      csv << [
        record.overall_rank,
        record.final_elapsed_seconds && time_format_hhmmss(record.final_elapsed_seconds),
        record.last_name,
        record.first_name,
        record.gender,
        record.birthdate&.strftime("%F"),
        record.country_code_ioc,
        record.bib_number,
        record.city,
      ]
    end
  end
else
  "No entrants have finished."
end
