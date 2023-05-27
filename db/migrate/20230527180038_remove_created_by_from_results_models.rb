class RemoveCreatedByFromResultsModels < ActiveRecord::Migration[7.0]
  def change
    remove_column :results_categories, :created_by, :integer
    remove_column :results_templates, :created_by, :integer
  end
end
