class ResultsTemplateCategory < ApplicationRecord
  belongs_to :template, optional: false, class_name: "ResultsTemplate", foreign_key: :results_template_id
  belongs_to :category, optional: false, class_name: "ResultsCategory", foreign_key: :results_category_id

  acts_as_list scope: :results_template_id
  validates_presence_of :category, :template

  def category_description
    category.description
  end

  def category_name
    category.name
  end
end
