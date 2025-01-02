module Api
  module V1
    class EventSpreadSerializer < ::Api::V1::BaseSerializer
      set_type :event_spread_displays

      attributes :name, :course_name, :organization_name, :display_style, :split_header_data
      link :self, :api_v1_url

      has_many :effort_times_rows

      attribute :event_start_time do |event|
        event.scheduled_start_time_local
      end

      attribute :event_start_time_local do |event|
        event.scheduled_start_time_local
      end

      attribute :event_scheduled_start_time_local do |event|
        event.scheduled_start_time_local
      end
    end
  end
end
