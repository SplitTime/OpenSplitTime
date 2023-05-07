# frozen_string_literal: true

class SendgridEvent < ApplicationRecord
  validates_presence_of :email, :event, :timestamp

  def timestamp=(timestamp)
    if timestamp.is_a?(Numeric)
      super Time.at(timestamp)
    elsif timestamp.respond_to?(:numeric?) && timestamp.numeric?
      super Time.at(timestamp.to_i)
    else
      super timestamp
    end
  end
end
