class CreateUsers < ActiveRecord::Migration
  def change
    create_table :users do |t|
      t.references :participant, index: true, foreign_key: true
      t.string :name
      t.string :role
      t.string :provider
      t.string :uid

      t.timestamps null: false
    end
  end
end
