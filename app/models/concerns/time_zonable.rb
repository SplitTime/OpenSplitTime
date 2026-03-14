# Used for models with one or more datetime attributes
# that need to be localized using a home_time_zone attribute.

module TimeZonable
  def self.past_time_threshold
    100.years.ago
  end

  def self.future_time_threshold
    100.years.from_now
  end

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
          unless time_zone_valid?(home_time_zone)
            send("#{attribute}=", nil)
            return
          end

          begin
            localized_time = time.to_s.in_time_zone(home_time_zone)

            if localized_time.nil? ||
               localized_time < TimeZonable.past_time_threshold ||
               localized_time > TimeZonable.future_time_threshold
              send("#{attribute}=", nil)
            else
              send("#{attribute}=", localized_time)
            end
          rescue ArgumentError
            send("#{attribute}=", nil)
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
