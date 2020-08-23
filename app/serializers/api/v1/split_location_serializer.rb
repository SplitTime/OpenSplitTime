# frozen_string_literal: true

module Api
  module V1
    class SplitLocationSerializer < ::Api::V1::BaseSerializer
      attributes :id, :course_name, :base_name, :distance_from_start, :latitude, :longitude, :elevation
      link :self, :url
    end
  end
end
