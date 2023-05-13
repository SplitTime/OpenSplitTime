# frozen_string_literal: true

# Used for models with one or more datetime attributes
# that need to be localized using a home_time_zone attribute.

module TimeZonable
  PAST_TIME_THRESHOLD = 100.years.ago
  FUTURE_TIME_THRESHOLD = 100.years.from_now

  def self.included(klass)
    klass.extend(ClassMethods)
  end

  module ClassMethods
    def zonable_attributes(*attributes)
      attributes.each(&method(:zonable_attribute))
    end

    def zonable_attribute(attribute)
      define_method :"#{attribute}_local" do
        return unless time_zone_valid?(home_time_zone)

        send(attribute)&.in_time_zone(home_time_zone)
      end

      define_method :"#{attribute}_local=" do |time|
        if time.present?
          raise ArgumentError, "#{attribute}_local cannot be set without a valid home_time_zone" unless time_zone_valid?(home_time_zone)

          begin
            localized_time = time.to_s.in_time_zone(home_time_zone)

            if localized_time.nil? || localized_time < PAST_TIME_THRESHOLD || localized_time > FUTURE_TIME_THRESHOLD
              errors.add(:"#{attribute}_local", "is not a valid datetime")
            else
              send("#{attribute}=", localized_time)
            end
          rescue ArgumentError
            errors.add(:"#{attribute}_local", "is not a valid datetime")
          end
        else
          send("#{attribute}=", nil)
        end
      end
    end
  end

  def time_zone_valid?(time_zone_string)
    time_zone_string && ActiveSupport::TimeZone[time_zone_string].present?
  end
end
