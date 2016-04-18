class CreateParticipants < ActiveRecord::Migration
  def change
    create_table :participants do |t|
      t.string :first_name, :null => false, limit: 32
      t.string :last_name, :null => false, limit: 64
      t.integer :gender, :null => false
      t.date :birthdate
      t.string :city
      t.string :state
      t.references :country, index: true, foreign_key: true
      t.string :email
      t.string :phone

      t.timestamps null: false
      t.integer :created_by, null: false
      t.integer :updated_by, null: false
    end
  end
end
