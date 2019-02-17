class AddPositionToResultsTemplateCategories < ActiveRecord::Migration[5.2]
  def change
    # This migration is rendered obsolete by the retroactive change in 20190213234208
    # which adds the :position attribute to begin with.

    # The retroactive change was necessary because the rake task called by migration 20190214033831
    # expects a :position column to exist on the results_template_categories table.

    # If you are having trouble, roll back migrations to before 20190213231256
    # and run migrations again.

    # add_column :results_template_categories, :position, :integer
    #
    # ResultsTemplate.all.each do |results_template|
    #   results_template.results_template_categories.order(:updated_at).each.with_index(1) do |rtc, index|
    #     rtc.update_column :position, index
    #   end
    # end
  end
end
