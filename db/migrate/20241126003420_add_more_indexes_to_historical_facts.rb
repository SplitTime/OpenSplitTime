class AddMoreIndexesToHistoricalFacts < ActiveRecord::Migration[7.0]
  def change
    add_index :historical_facts, [:organization_id, :personal_info_hash], name: "index_hf_on_organization_and_hash"
    add_index :historical_facts, [:organization_id, :personal_info_hash, :person_id], name: "index_hf_on_organization_and_hash_and_person"
  end
end
