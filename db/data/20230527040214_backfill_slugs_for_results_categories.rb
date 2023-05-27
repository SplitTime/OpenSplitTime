# frozen_string_literal: true

class BackfillSlugsForResultsCategories < ActiveRecord::Migration[7.0]
  def up
    ResultsCategory.find_each(&:save)
  end

  def down
    ResultsCategory.update_all(slug: nil)
  end
end
