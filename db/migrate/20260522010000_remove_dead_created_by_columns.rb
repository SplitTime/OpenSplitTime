class RemoveDeadCreatedByColumns < ActiveRecord::Migration[8.1]
  def change
    remove_column :courses, :created_by, :integer
    remove_column :efforts, :created_by, :integer
    remove_column :events, :created_by, :integer
    remove_column :historical_facts, :created_by, :integer
    remove_column :notifications, :created_by, :integer
    remove_column :people, :created_by, :integer
    remove_column :splits, :created_by, :integer
  end
end
