# frozen_string_literal: true

module Api
  module V1
    class SplitTimeSerializer < ::Api::V1::BaseSerializer
      set_type :split_times

      attributes :id, :effort_id, :lap, :split_id, :bitkey, :absolute_time, :data_status, :pacer, :remarks
      link :self, :api_v1_url
    end
  end
end
