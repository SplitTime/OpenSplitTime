# Used for models with a 'concealed' attribute. Includes conditional logic for use on models
# that do not currently but might contain a 'concealed' attribute in the future.

module Concealable
  extend ActiveSupport::Concern

  include SetOperations

  included do
    scope :concealed, -> { column_names.include?('concealed') ? where(concealed: true) : none }
    scope :visible, -> { column_names.include?('concealed') ? where(concealed: false) : all }
  end

  def concealed?
    attributes.has_key?('concealed') ? attributes['concealed'] : false
  end

  def visible?
    attributes.has_key?('concealed') ? !attributes['concealed'] : true
  end

  # May be overridden in models
  def should_be_concealed?
    false
  end
end