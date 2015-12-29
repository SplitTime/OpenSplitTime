class CreateParticipants < ActiveRecord::Migration
  def change
    create_table :participants do |t|
      t.string :first_name
      t.string :last_name
      t.string :gender
      t.date :birthdate
      t.string :home_city
      t.string :home_state
      t.string :home_country

      t.timestamps null: false
    end
  end
end
