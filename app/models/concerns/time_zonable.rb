# frozen_string_literal: true

# Used for models with one or more datetime attributes
# that need to be localized using a home_time_zone attribute.

module TimeZonable
  def self.included(klass)
    klass.extend(ClassMethods)
  end

  module ClassMethods
    def zonable_attributes(*attributes)
      attributes.each(&method(:zonable_attribute))
    end

    def zonable_attribute(attribute)
      define_method :"#{attribute}_local" do
        unless time_zone_valid?(home_time_zone)
          return nil
        end
        send(attribute)&.in_time_zone(home_time_zone)
      end

      define_method :"#{attribute}_local=" do |time|
        if time.present?
          unless time_zone_valid?(home_time_zone)
            raise ArgumentError, "#{attribute}_local cannot be set without a valid home_time_zone"
          end
          self.send("#{attribute}=", time.to_s.in_time_zone(home_time_zone))
        else
          self.send("#{attribute}=", nil)
        end
      end
    end
  end

  def time_zone_valid?(time_zone_string)
    time_zone_string && ActiveSupport::TimeZone[time_zone_string].present?
  end
end
