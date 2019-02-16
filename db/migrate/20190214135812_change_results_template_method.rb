class ChangeResultsTemplateMethod < ActiveRecord::Migration[5.2]
  def change
    # This migration is rendered obsolete by the retroactive change in 20190213231256
    # which names the attribute as :aggregation_method to begin with.
    # Naming an ActiveRecord attribute 'method' is problematic for several reasons
    # that should have been clear in advance but became abundantly clear after the fact.

    # The retroactive change was necessary because the rake task called by migration 20190214033831
    # expects a column on the results_templates table to be named :aggregation_method.

    # If you are having trouble, roll back migrations to before 20190213231256
    # and run migrations again.

    # rename_column :results_templates, :method, :aggregation_method
  end
end
