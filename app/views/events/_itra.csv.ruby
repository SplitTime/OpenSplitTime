if records.present?
    CSV.generate do |csv|
        csv << [
                 "Ranking",
                 "Time",
                 "Last name",
                 "First name",
                 "Birthdate",
                 "Gender",
                 "Nationality",
                 "City",
                 "Bib number"
               ]

        records.each do |record|
            csv << [
                     record.overall_rank,
                     record.final_elapsed_seconds && time_format_hhmmss(record.final_elapsed_seconds),
                     record.last_name,
                     record.first_name,
                     record.birthdate&.strftime("%F"),
                     record.gender,
                     record.country_code,
                     record.city,
                     record.bib_number
                   ]
        end
    end
else
    'No entrants have finished.'
end
