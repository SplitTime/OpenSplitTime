if records.present?
    header = "Finishers for #{@presenter.name} as of #{day_time_full_format(current_time)}"
    CSV.generate do |csv|
        csv << [header] if header
        csv << %w(place time first last age gender city state bib)
        records.each do |record|
            csv << [record.overall_rank,
                    record.final_time_from_start && time_format_hhmmss(record.final_time_from_start),
                    record.first_name,
                    record.last_name,
                    record.age,
                    record.gender,
                    record.city,
                    record.state_code,
                    record.bib_number]
        end
    end
else
    'No entrants have finished.'
end
