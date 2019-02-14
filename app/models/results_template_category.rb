class ResultsTemplateCategory < ApplicationRecord
  belongs_to :results_template, optional: false
  belongs_to :results_category, optional: false

  validates_presence_of :results_category, :results_template
end
