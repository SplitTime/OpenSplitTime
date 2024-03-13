class CreateProjectionAssessments < ActiveRecord::Migration[7.0]
  def change
    create_table :projection_assessments do |t|
      t.references :projection_assessment_run, null: false, foreign_key: true
      t.references :effort, null: false, foreign_key: true
      t.datetime :projected_early
      t.datetime :projected_best
      t.datetime :projected_late
      t.datetime :actual

      t.timestamps
    end
  end
end
