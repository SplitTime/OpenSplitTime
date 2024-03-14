class CreateProjectionAssessmentRuns < ActiveRecord::Migration[7.0]
  def change
    create_table :projection_assessment_runs do |t|
      t.references :event, null: false, foreign_key: true
      t.integer :completed_lap, null: false
      t.integer :completed_split_id, null: false
      t.integer :completed_bitkey, null: false
      t.integer :projected_lap, null: false
      t.integer :projected_split_id, null: false
      t.integer :projected_bitkey, null: false
      t.integer :status
      t.string :error_message
      t.integer :success_count
      t.integer :failure_count
      t.datetime :started_at
      t.integer :elapsed_time

      t.timestamps
    end
  end
end
