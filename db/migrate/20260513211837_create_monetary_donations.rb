class CreateMonetaryDonations < ActiveRecord::Migration[8.1]
  def change
    create_table :monetary_donations do |t|
      t.references :organization, null: false, foreign_key: true
      t.date :received_on, null: false
      t.decimal :amount, precision: 10, scale: 2, null: false
      t.string :source, null: false
      t.text :note
      t.timestamps
    end

    add_index :monetary_donations, [:organization_id, :received_on]
  end
end
