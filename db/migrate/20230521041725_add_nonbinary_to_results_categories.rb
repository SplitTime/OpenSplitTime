class AddNonbinaryToResultsCategories < ActiveRecord::Migration[7.0]
  def change
    add_column :results_categories, :nonbinary, :boolean, default: false
  end
end
