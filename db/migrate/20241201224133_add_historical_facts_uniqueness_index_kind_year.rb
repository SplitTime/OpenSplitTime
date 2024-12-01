class AddHistoricalFactsUniquenessIndexKindYear < ActiveRecord::Migration[7.0]
  def change
    # dns, volunteer_year, volunteer_year_major, lottery_ticket_count_legacy, lottery_division_legacy, dnf, finished, lottery_application
    add_index :historical_facts, [:organization_id, :person_id, :year, :kind],
              where: "kind in (0, 1, 2, 7, 8, 9, 10, 11)",
              name: "index_historical_facts_uniq_kind_year"
    # volunteer_multi
    add_index :historical_facts, [:organization_id, :person_id, :kind],
              where: "kind = 3",
              name: "index_historical_facts_uniq_kind"
  end
end
