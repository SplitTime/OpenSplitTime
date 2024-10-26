class CreateHistoricalFacts < ActiveRecord::Migration[7.0]
  def change
    create_table :historical_facts do |t|
      t.references :event, foreign_key: true
      t.references :person, foreign_key: true
      t.string :first_name, null: false
      t.string :last_name, null: false
      t.date :birthdate, null: false
      t.integer :gender, null: false
      t.string :address
      t.string :city
      t.string :state_code
      t.string :country_code
      t.string :state_name
      t.string :country_name
      t.string :email
      t.string :phone
      t.string :emergency_contact
      t.string :emergency_phone
      t.integer :kind, null: false
      t.integer :quantity
      t.string :comments

      t.timestamps
    end
  end
end
