# frozen_string_literal: true

class EventGroupSerializer < BaseSerializer
  attributes :id, :name, :organization_id, :concealed, :available_live, :auto_live_times, :monitor_pacers, :slug,
             :combined_split_attributes, :ungrouped_split_attributes
  link(:self) { api_v1_event_group_path(object) }

  has_many :events
  belongs_to :organization

  def combined_split_attributes
    CombineEventGroupSplitAttributes.perform(object, pair_by_location: pair_by_location?)
  end

  def ungrouped_split_attributes
    CombineEventGroupSplitAttributes.perform(object, pair_by_location: false)
  end

  def pair_by_location?
    object.location_grouped?
  end
end
