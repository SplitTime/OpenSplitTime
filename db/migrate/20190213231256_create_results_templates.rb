class CreateResultsTemplates < ActiveRecord::Migration[5.2]
  def up
    create_table :results_templates do |t|
      t.references :organization, foreign_key: true
      t.string :name, unique: true
      t.integer :method
      t.integer :podium_size
      t.integer :point_system, array: true, default: '{}'
      t.string :temp_key
      t.string :slug, null: false
      t.integer :created_by
      t.integer :updated_by

      t.timestamps
    end
  end

  def down
    drop_table :results_templates
  end
end
