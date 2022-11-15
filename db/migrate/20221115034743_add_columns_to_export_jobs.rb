class AddColumnsToExportJobs < ActiveRecord::Migration[7.0]
  def change
    add_column :export_jobs, :controller_name, :string
    add_column :export_jobs, :resource_class_name, :string
    add_column :export_jobs, :sql_string, :string
    add_column :export_jobs, :error_message, :string
  end
end
