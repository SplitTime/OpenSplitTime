class AddFinishedAtToImportJobs < ActiveRecord::Migration[6.1]
  def change
    add_column :import_jobs, :finished_at, :datetime
  end
end
