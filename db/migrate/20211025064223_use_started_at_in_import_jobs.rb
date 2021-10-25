class UseStartedAtInImportJobs < ActiveRecord::Migration[6.1]
  def change
    add_column :import_jobs, :started_at, :datetime
    remove_column :import_jobs, :elapsed_time, :integer
  end
end
