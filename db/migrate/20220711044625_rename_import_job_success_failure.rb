class RenameImportJobSuccessFailure < ActiveRecord::Migration[7.0]
  def change
    rename_column :import_jobs, :success_count, :succeeded_count
    rename_column :import_jobs, :failure_count, :failed_count
  end
end
