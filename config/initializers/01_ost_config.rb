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

  def self.timestamp_bot_detection?
    cast_to_boolean ::ENV["TIMESTAMP_BOT_DETECTION"]
  end
end
