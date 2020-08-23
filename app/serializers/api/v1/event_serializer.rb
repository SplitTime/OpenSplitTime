# frozen_string_literal: true

module Api
  module V1
    class EventSerializer < ::Api::V1::BaseSerializer
      attributes :id, :course_id, :organization_id, :name, :start_time, :scheduled_start_time, :home_time_zone, :start_time_local,
                 :start_time_in_home_zone, :scheduled_start_time_local, :concealed, :laps_required, :maximum_laps,
                 :multi_lap, :slug, :short_name, :multiple_sub_splits, :parameterized_split_names, :split_names
      link :self, :url

      has_many :efforts
      has_many :splits
      has_many :aid_stations
      belongs_to :course
      belongs_to :event_group

      # Included for backward compatibility
      def start_time
        object.scheduled_start_time
      end

      # Included for backward compatibility
      def start_time_in_home_zone
        object.scheduled_start_time_local
      end

      # Included for backward compatibility
      def start_time_local
        object.scheduled_start_time_local
      end

      def multi_lap
        object.multiple_laps?
      end

      def concealed
        object.event_group.concealed?
      end

      def multiple_sub_splits
        object.multiple_sub_splits?
      end

      def parameterized_split_names
        object.splits.map(&:parameterized_base_name)
      end

      def split_names
        object.splits.map(&:base_name)
      end
    end
  end
end
