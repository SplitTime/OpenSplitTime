# frozen_string_literal: true

module Api
  module V1
    class EventGroupSerializer < ::Api::V1::BaseSerializer
      set_type :event_groups

      attributes :id, :name, :organization_id, :concealed, :available_live, :monitor_pacers, :slug,
                 :multi_lap, :maximum_laps, :unpaired_data_entry_groups, :home_time_zone
      link :self, :api_v1_url

      has_many :events
      belongs_to :organization

      attribute :data_entry_groups do |event_group|
        CombineEventGroupSplitAttributes.perform(event_group,
                                                 pair_by_location: event_group.location_grouped?,
                                                 node_attributes: [:sub_split_kind, :label, :split_name, :parameterized_split_name])
      end

      attribute :unpaired_data_entry_groups do |event_group|
        CombineEventGroupSplitAttributes.perform(event_group,
                                                 pair_by_location: false,
                                                 node_attributes: [:sub_split_kind, :label, :split_name, :parameterized_split_name])
      end
    end
  end
end
