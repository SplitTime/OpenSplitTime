class AddFixedPositionToResultsTemplateCategories < ActiveRecord::Migration[5.2]
  def change
    add_column :results_template_categories, :fixed_position, :boolean
  end
end
