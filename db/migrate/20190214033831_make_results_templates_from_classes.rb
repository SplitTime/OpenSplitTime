# class MakeResultsTemplatesFromClasses < ActiveRecord::Migration[5.2]
#   def up
#     Rake::Task["create_records:results_templates"].invoke
#   end

#   def down
#     ResultsTemplateCategory.delete_all
#     ResultsCategory.delete_all
#     ResultsTemplate.delete_all
#     puts "Deleted all ResultsTemplateCategories, ResultsCategories, and ResultsTemplates"
#   end
# end


class MakeResultsTemplatesFromClasses < ActiveRecord::Migration[5.2]
  def up
    # No-op for local development.
    # Original migration populated results templates via a rake task:
    # Rake::Task["create_records:results_templates"].invoke
    #
    # We skip this to avoid dependency issues with results_categories
    # columns that may not exist yet.
  end

  def down
    # No-op: we didn't create or modify any records here in this version
    # of the migration, so there is nothing to roll back.
    #
    # Original code:
    # ResultsTemplateCategory.delete_all
    # ResultsCategory.delete_all
    # ResultsTemplate.delete_all
    # puts "Deleted all ResultsTemplateCategories, ResultsCategories, and ResultsTemplates"
  end
end
