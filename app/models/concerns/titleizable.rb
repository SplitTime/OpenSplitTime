# frozen_string_literal: true

# Used for models with one or more string attributes that should be
# titleized (for example, first names, last names, and place-names).
module Titleizable
  extend ::ActiveSupport::Concern

  included do
    before_validation :titleize_record
    class_attribute :titleizable_attribute_names
    self.titleizable_attribute_names = []
  end

  module ClassMethods
    def titleize_attributes(*attributes)
      attributes.each(&method(:titleize_attribute))
    end

    def titleize_attribute(attribute)
      self.titleizable_attribute_names << attribute.to_s
    end

    def titleize_value(value)
      return unless value.present?
      # Only titleize the value if it is all lowercase or all uppercase.
      # This avoids inadvertently titleizing names intended to have mixed
      # case, like "McDonald"
      return unless value.downcase == value || value.upcase == value

      value.titleize
    end
  end

  def titleize_record
    titleizable_attributes = attributes.slice(*self.titleizable_attribute_names)

    titleizable_attributes.each do |attr, value|
      original_value = value
      value = self.class.titleize_value(value)
      self.write_attribute(attr, value) if original_value != value
    end

    self
  end
end
