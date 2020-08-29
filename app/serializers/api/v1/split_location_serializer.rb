# frozen_string_literal: true

# TODO: This serializer should be removed and clients should
# instead use splits endpoints.
module Api
  module V1
    class SplitLocationSerializer < ::Api::V1::BaseSerializer
      set_type :split_locations

      attributes :id, :course_name, :base_name, :distance_from_start, :latitude, :longitude, :elevation

      link :self, :api_v1_url
    end
  end
end
