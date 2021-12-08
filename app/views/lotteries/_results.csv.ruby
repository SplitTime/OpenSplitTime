# frozen_string_literal: true

if lottery.entrants.exists?
  ::CSV.generate do |csv|
    csv << ["Results for #{lottery.name}"]

    lottery.divisions.each do |division|
      csv << ["\n"]
      csv << [division.name]
      csv << ["Accepted"]

      division.winning_entrants.each do |entrant|
        csv << [
          entrant.first_name,
          entrant.last_name,
          entrant.gender,
          entrant.city,
          entrant.state_name,
          entrant.country_name,
        ]
      end

      csv << ["Wait List"]
      division.wait_list_entrants.each do |entrant|
        csv << [
          entrant.first_name,
          entrant.last_name,
          entrant.gender,
          entrant.city,
          entrant.state_name,
          entrant.country_name,
        ]
      end
    end
  end
else
  "No records to export."
end
