class RenameTempKeyToIdentifier < ActiveRecord::Migration[7.0]
  def change
    rename_column :results_categories, :temp_key, :identifier
    rename_column :results_templates, :temp_key, :identifier
  end
end
