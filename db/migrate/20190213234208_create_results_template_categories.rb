class CreateResultsTemplateCategories < ActiveRecord::Migration[5.2]
  def change
    create_table :results_template_categories do |t|
      t.references :results_template, foreign_key: true, nil: false
      t.references :results_category, foreign_key: true, nil: false

      t.timestamps
    end
  end
end
