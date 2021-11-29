# frozen_string_literal: true

module OstConfig
  # All variations of "false", "f", "off", "0", "", and nil
  # will return false; all other values will return true.
  # For a complete list of values that will evaluate to false,
  # see ::ActiveModel::Type::Boolean::FALSE_VALUES
  def self.cast_to_boolean(value)
    return false unless value.present?

    ::ActiveModel::Type::Boolean.new.cast(value)
  end

  def self.full_uri
    ::ENV["FULL_URI"]
  end

  def self.google_analytics_4_measurement_id
    ::ENV["GOOGLE_ANALYTICS_4_MEASUREMENT_ID"]
  end

  def self.google_analytics_4_property_id
    ::ENV["GOOGLE_ANALYTICS_4_PROPERTY_ID"]
  end

  def self.scout_apm_sample_rate
    ::ENV["SCOUT_APM_SAMPLE_RATE"]&.to_f || 1.0
  end

  def self.timestamp_bot_detection?
    cast_to_boolean ::ENV["TIMESTAMP_BOT_DETECTION"]
  end
end
