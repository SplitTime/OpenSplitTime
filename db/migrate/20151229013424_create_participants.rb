class CreateParticipants < ActiveRecord::Migration
  def change
    create_table :participants do |t|
      t.string :first_name
      t.string :last_name
      t.string :gender
      t.date :birthdate
      t.string :city
      t.string :state
      t.references :country, foreign_key: true
      t.string :email
      t.string :phone

      t.timestamps null: false
    end
  end
end
