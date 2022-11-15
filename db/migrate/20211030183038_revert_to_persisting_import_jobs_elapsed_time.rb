class RevertToPersistingImportJobsElapsedTime < ActiveRecord::Migration[6.1]
  def change
    remove_column :import_jobs, :finished_at, :datetime
    add_column :import_jobs, :elapsed_time, :integer
  end
end
