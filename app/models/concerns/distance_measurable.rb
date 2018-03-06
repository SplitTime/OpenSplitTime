module DistanceMeasurable
  extend ActiveSupport::Concern

  D_TO_R = Math::PI / 180.0
  RADIUS = 6_371_000 # Earth's mean radius in meters

  def distance_from(other)
    return unless latr && lonr && other.latr && other.lonr
    d_lat = other.latr - latr
    d_lon = other.lonr - lonr
    a = Math.sin(d_lat / 2)**2 + Math.cos(latr) * Math.cos(other.latr) * Math.sin(d_lon / 2)**2
    c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a))
    RADIUS * c
  end

  protected

  def latr
    latitude && latitude * D_TO_R
  end

  def lonr
    longitude && longitude * D_TO_R
  end
end
