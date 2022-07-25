# frozen_string_literal: true

class SyncTrackPointsJob < ApplicationJob
  MAX_POINTS = 1000

  queue_as :default

  def perform(course)
    if course.gpx.attached?
      doc = Nokogiri::XML(course.gpx.download)
      points = doc.xpath('//xmlns:trkpt')
      json_points = points.map { |trkpt| { lat: trkpt.xpath('@lat').to_s.to_f, lon: trkpt.xpath('@lon').to_s.to_f } }
      filtered_json_points = filter(json_points)

      course.update!(track_points: filtered_json_points)
    else
      course.update!(track_points: [])
    end
  end

  private

  def filter(points)
    points_size = points.size
    return points if points_size <= MAX_POINTS

    trim_factor = points_size / MAX_POINTS.to_f
    indexes_to_save = (0..MAX_POINTS).map { |i| (i * trim_factor).round(0) }.to_set
    indexes_to_save << points_size - 1 # Ensure the last point is always included

    points.select.with_index { |_, i| i.in?(indexes_to_save) }
  end
end
