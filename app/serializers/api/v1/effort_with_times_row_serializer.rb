# frozen_string_literal: true

module Api
  module V1
    class EffortWithTimesRowSerializer < ::Api::V1::BaseSerializer
      attributes :event_short_name, :event_split_header_data
      set_type :effort_with_times_row

      has_one :effort_times_row
    end
  end
end
