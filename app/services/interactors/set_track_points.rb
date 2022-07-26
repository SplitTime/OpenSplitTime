# frozen_string_literal: true

module Interactors
  class SetTrackPoints
    include Interactors::Errors

    MAX_POINTS = 1000

    def self.perform!(course)
      new(course).perform!
    end

    def initialize(course)
      @course = course
      @response = ::Interactors::Response.new([])
    end

    def perform!
      if course.gpx.attached?

        Rails.logger.info "=============================================================="
        Rails.logger.info "gpx is attached"

        doc = Nokogiri::XML(course.gpx.download)

        Rails.logger.info "Filename: #{course.gpx.blob.filename}"
        Rails.logger.info "=============================================================="

        points = doc.xpath('//xmlns:trkpt')
        json_points = points.map { |trkpt| { lat: trkpt.xpath('@lat').to_s.to_f, lon: trkpt.xpath('@lon').to_s.to_f } }
        filtered_json_points = filter(json_points)

        errors << resource_error_object(course) unless course.update(track_points: filtered_json_points)
      else

        Rails.logger.info "=============================================================="
        Rails.logger.info "gpx is not attached"
        Rails.logger.info "=============================================================="

        errors << resource_error_object(course) unless course.update(track_points: [])
      end

    rescue ActiveRecord::RecordInvalid => e
      response.errors << active_record_error(e)
    rescue Nokogiri::ParseException => e
      response.errors << nokogiri_parse_error(e)
    ensure
      return response
    end

    private

    attr_reader :course, :response

    def filter(points)
      points_size = points.size
      return points if points_size <= MAX_POINTS

      trim_factor = points_size / MAX_POINTS.to_f
      indexes_to_save = (0..MAX_POINTS).map { |i| (i * trim_factor).round(0) }.to_set
      indexes_to_save << points_size - 1 # Ensure the last point is always included

      points.select.with_index { |_, i| i.in?(indexes_to_save) }
    end
  end
end
