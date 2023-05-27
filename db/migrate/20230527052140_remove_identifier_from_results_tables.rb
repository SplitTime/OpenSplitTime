class RemoveIdentifierFromResultsTables < ActiveRecord::Migration[7.0]
  def change
    remove_column :results_categories, :identifier, :string
    remove_column :results_templates, :identifier, :string
  end
end
