class AddSuccessAndFailureCountsToImportJobs < ActiveRecord::Migration[6.1]
  def change
    add_column :import_jobs, :success_count, :integer
    add_column :import_jobs, :failure_count, :integer
  end
end
