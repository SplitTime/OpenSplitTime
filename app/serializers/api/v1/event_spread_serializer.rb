# frozen_string_literal: true

module Api
  module V1
    class EventSpreadSerializer < ::Api::V1::BaseSerializer
      attributes :name, :course_name, :organization_name, :event_start_time, :event_start_time_local, :display_style, :split_header_data
      link :self, :url

      has_many :effort_times_rows

      def event_start_time
        object.scheduled_start_time_local
      end

      def event_start_time_local
        object.scheduled_start_time_local
      end

      def event_scheduled_start_time_local
        object.scheduled_start_time_local
      end
    end
  end
end
