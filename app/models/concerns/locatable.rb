# frozen_string_literal: true

module Locatable
  extend ActiveSupport::Concern

  def distance_from(other)
    location&.distance_from(other.location)
  end

  def same_location?(other)
    self.location && other.location && self.location == other.location
  end

  def different_location?(other)
    same = same_location?(other)
    same.nil? ? nil : !same
  end

  def location
    return nil unless latitude && longitude
    Location.new(latitude, longitude, distance_threshold)
  end

  protected

  def distance_threshold
    raise NotImplementedError, 'Including class must implement DISTANCE_THRESHOLD' unless defined?(self.class::DISTANCE_THRESHOLD)
    self.class::DISTANCE_THRESHOLD
  end
end
