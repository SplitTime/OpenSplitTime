class ApplicationRecord < ActiveRecord::Base
  self.abstract_class = true

  scope :standard_includes, -> { all } # May be overriden in models
end
