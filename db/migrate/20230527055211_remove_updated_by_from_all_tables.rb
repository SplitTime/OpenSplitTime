class RemoveUpdatedByFromAllTables < ActiveRecord::Migration[7.0]
  def change
    remove_column :courses, :updated_by, :integer
    remove_column :efforts, :updated_by, :integer
    remove_column :events, :updated_by, :integer
    remove_column :event_groups, :updated_by, :integer
    remove_column :notifications, :updated_by, :integer
    remove_column :organizations, :updated_by, :integer
    remove_column :people, :updated_by, :integer
    remove_column :raw_times, :updated_by, :integer
    remove_column :results_categories, :updated_by, :integer
    remove_column :results_templates, :updated_by, :integer
    remove_column :splits, :updated_by, :integer
    remove_column :split_times, :updated_by, :integer
  end
end
