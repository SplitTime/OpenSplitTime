if @event_display.event_finished?
    CSV.generate do |csv|
        csv << %w(place time first last age gender city state dob bib status)
        @event_display.ranked_effort_rows.each do |row|
            csv << [row.overall_rank,
                    row.final_time && time_format_hhmmss(row.final_time),
                    row.first_name,
                    row.last_name,
                    row.age,
                    row.gender,
                    row.city,
                    row.state_code,
                    row.birthdate,
                    row.bib_number,
                    row.ultrasignup_finish_status]
        end
    end
else
    'OpenSplitTime thinks that one or more efforts is still in progress. You need to establish drops/stops before exporting.'
end