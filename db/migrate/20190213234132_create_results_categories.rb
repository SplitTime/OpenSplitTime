class CreateResultsCategories < ActiveRecord::Migration[5.2]
  def change
    create_table :results_categories do |t|
      t.references :organization, foreign_key: true
      t.string :name, unique: true
      t.boolean :male
      t.boolean :female
      t.integer :low_age
      t.integer :high_age
      t.string :temp_key
      t.integer :created_by
      t.integer :updated_by

      t.timestamps
    end
  end
end
