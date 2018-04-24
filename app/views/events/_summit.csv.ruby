CSV.generate do |csv|
    csv << %w(Bib Finish)
    @event_display.ranked_effort_rows.sort_by(&:overall_rank).each do |row|
        finish_time = row.finished? ? row.final_day_and_time.strftime('%H:%M:%S') : nil
        csv << [row.bib_number,
                finish_time]
    end
end
