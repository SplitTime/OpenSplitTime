# frozen_string_literal: true

class EventGroupSerializer < BaseSerializer
  attributes :id, :name, :organization_id, :concealed, :available_live, :auto_live_times, :monitor_pacers, :slug,
             :multi_lap, :maximum_laps, :combined_split_attributes, :ungrouped_split_attributes, :data_entry_groups, :unpaired_data_entry_groups
  link(:self) { api_v1_event_group_path(object) }

  has_many :events
  belongs_to :organization

  def combined_split_attributes
    CombineEventGroupSplitAttributes.perform(object,
                                             pair_by_location: pair_by_location?,
                                             node_attributes: [:event_split_ids, :sub_split_kind, :label, :split_name, :display_split_name])
  end

  def ungrouped_split_attributes
    CombineEventGroupSplitAttributes.perform(object,
                                             pair_by_location: false,
                                             node_attributes: [:event_split_ids, :sub_split_kind, :label, :split_name, :display_split_name])
  end

  def data_entry_groups
    CombineEventGroupSplitAttributes.perform(object,
                                             pair_by_location: pair_by_location?,
                                             node_attributes: [:sub_split_kind, :label, :split_name, :parameterized_split_name])
  end

  def unpaired_data_entry_groups
    CombineEventGroupSplitAttributes.perform(object,
                                             pair_by_location: false,
                                             node_attributes: [:sub_split_kind, :label, :split_name, :parameterized_split_name])
  end

  def maximum_laps
    laps_required_array = object.events.map(&:laps_required)
    laps_required_array.min == 0 ? nil : laps_required_array.max
  end

  def multi_lap
    object.multiple_laps?
  end

  def pair_by_location?
    object.location_grouped?
  end
end
