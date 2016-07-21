CSV.generate do |csv|
    csv << %w(place time first last age gender city state dob bib status)
    @event_display.effort_rows.each do |row|
        csv << [row.overall_place,
                row.finish_time ? time_format_hhmmss(row.finish_time) : nil,
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
