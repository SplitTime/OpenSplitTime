class RemoveSlugFromResultsCategories < ActiveRecord::Migration[5.2]
  def change
    remove_column :results_categories, :slug, :string
  end
end
