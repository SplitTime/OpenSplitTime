# frozen_string_literal: true

class SendgridEvent < ApplicationRecord
  def timestamp=(timestamp)
    if timestamp.is_a?(Numeric)
      super Time.at(timestamp)
    else
      super timestamp
    end
  end
end
