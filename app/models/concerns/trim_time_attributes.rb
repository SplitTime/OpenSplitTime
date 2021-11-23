# frozen_string_literal: true

# Used for models with one or more datetime attributes
# that need to be trimmed to integer seconds.

module TrimTimeAttributes
  extend ::ActiveSupport::Concern

  included do
    before_validation :trim_time_attributes
    class_attribute :trimmable_time_attribute_names
    self.trimmable_time_attribute_names = []
  end

  module ClassMethods
    def trim_time_attributes(*attributes)
      attributes.each(&method(:trim_time_attribute))
    end

    def trim_time_attribute(attribute)
      trimmable_time_attribute_names << attribute.to_s
    end
  end

  private

  def trim_time_attributes
    trimmable_time_attributes = attributes.slice(*trimmable_time_attribute_names)

    trimmable_time_attributes.each do |attr, value|
      if value.present?
        new_value = ::Time.zone.at(value.to_i)
        send("#{attr}=", new_value) if new_value != value
      end
    end

    # Don't cancel later callbacks
    true
  end
end
