class ChangeResultsTemplateMethod < ActiveRecord::Migration[5.2]
  def change
    rename_column :results_templates, :method, :aggregation_method
  end
end
