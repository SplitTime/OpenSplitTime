class CreateCredentials < ActiveRecord::Migration[7.0]
  def change
    create_table :credentials do |t|
      t.references :user, null: false, foreign_key: true
      t.string :service, null: false
      t.string :key, null: false
      t.string :value, null: false

      t.timestamps
    end
  end
end
