class AddSlugToResultsCategories < ActiveRecord::Migration[7.0]
  def change
    add_column :results_categories, :slug, :string
  end
end
