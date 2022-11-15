class CreateExportJobs < ActiveRecord::Migration[7.0]
  def change
    create_table :export_jobs do |t|
      t.references :user, null: false, foreign_key: true
      t.integer :status
      t.string :source_url
      t.datetime :started_at
      t.integer :elapsed_time

      t.timestamps
    end
  end
end
