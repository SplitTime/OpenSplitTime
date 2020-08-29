# frozen_string_literal: true

module Api
  module V1
    class AidStationSerializer < ::Api::V1::BaseSerializer
      set_type :aid_stations

      attributes :id, :event_id, :split_id
      link :self, :api_v1_url

      belongs_to :event
      belongs_to :split
    end
  end
end
