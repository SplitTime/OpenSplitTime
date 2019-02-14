class AddPositionToResultsTemplateCategories < ActiveRecord::Migration[5.2]
  def change
    add_column :results_template_categories, :position, :integer

    ResultsTemplate.all.each do |results_template|
      results_template.results_template_categories.order(:updated_at).each.with_index(1) do |rtc, index|
        rtc.update_column :position, index
      end
    end
  end
end
