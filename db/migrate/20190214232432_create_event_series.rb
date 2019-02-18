class CreateEventSeries < ActiveRecord::Migration[5.2]
  def change
    create_table :event_series do |t|
      t.references :organization, foreign_key: true
      t.references :results_template, foreign_key: true
      t.string :name
      t.string :slug

      t.timestamps
    end
  end
end
