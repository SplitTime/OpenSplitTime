class RemoveSlugFromResultsCategories < ActiveRecord::Migration[5.2]
  # This migration is rendered obsolete by the retroactive change in 20190213234132
  # which does not add the :slug attribute.

  # The retroactive change was necessary because the rake task called by migration 20190214033831
  # does not add slugs to ResultsCategory attributes.

  # If you are having trouble, roll back migrations to before 20190213231256
  # and run migrations again.

  # def change
  #   remove_column :results_categories, :slug, :string
  # end
end
