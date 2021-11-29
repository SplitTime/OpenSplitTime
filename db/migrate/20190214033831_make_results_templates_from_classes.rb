class MakeResultsTemplatesFromClasses < ActiveRecord::Migration[5.2]
  def up
    Rake::Task['create_records:results_templates'].invoke
  end

  def down
    ResultsTemplateCategory.delete_all
    ResultsCategory.delete_all
    ResultsTemplate.delete_all
    puts 'Deleted all ResultsTemplateCategories, ResultsCategories, and ResultsTemplates'
  end
end
