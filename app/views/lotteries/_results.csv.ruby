require "csv"

if lottery.entrants.exists?
  ::CSV.generate do |csv|
    csv << ["Results for #{lottery.name}"]

    lottery.divisions.ordered_by_name.each do |division|
      csv << ["\n"]
      csv << [division.name]
      csv << ["Accepted"]

      division.accepted_entrants.each.with_index(1) do |entrant, i|
        csv << [
          i,
          entrant.first_name,
          entrant.last_name,
          entrant.gender,
          entrant.city,
          entrant.state_name,
          entrant.country_name,
        ]
      end

      csv << ["Wait List"]
      division.waitlisted_entrants.each.with_index(1) do |entrant, i|
        csv << [
          i,
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
