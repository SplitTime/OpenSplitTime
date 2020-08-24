# frozen_string_literal: true

module Api
  module V1
    class EventSerializer < ::Api::V1::BaseSerializer
      set_type :events

      attributes :id, :course_id, :organization_id, :name, :start_time, :scheduled_start_time, :home_time_zone, :start_time_local,
                 :start_time_in_home_zone, :scheduled_start_time_local, :concealed, :laps_required, :maximum_laps,
                 :multi_lap, :slug, :short_name, :multiple_sub_splits, :parameterized_split_names, :split_names
      link :self, :api_v1_url

      has_many :efforts
      has_many :splits
      has_many :aid_stations
      belongs_to :course
      belongs_to :event_group

      # Included for backward compatibility
      attribute :start_time do |event|
        event.scheduled_start_time
      end

      # Included for backward compatibility
      attribute :start_time_in_home_zone do |event|
        event.scheduled_start_time_local
      end

      # Included for backward compatibility
      attribute :start_time_local do |event|
        event.scheduled_start_time_local
      end

      attribute :multi_lap do |event|
        event.multiple_laps?
      end

      attribute :multiple_sub_splits do |event|
        event.multiple_sub_splits?
      end

      attribute :parameterized_split_names do |event|
        event.splits.map(&:parameterized_base_name)
      end

      attribute :split_names do |event|
        event.splits.map(&:base_name)
      end
    end
  end
end
