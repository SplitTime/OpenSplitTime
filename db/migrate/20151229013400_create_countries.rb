class CreateCountries < ActiveRecord::Migration
  def change
    create_table :countries do |t|
      t.string :code  # ISO 3166 2-character country code
      t.string :name

      t.timestamps null: false
    end
  end
end
