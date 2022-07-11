class AddIgnoredCountToImportJobs < ActiveRecord::Migration[7.0]
  def change
    add_column :import_jobs, :ignored_count, :integer
  end
end
