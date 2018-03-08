class EventGroupSerializer < BaseSerializer
  attributes :id, :name, :organization_id, :concealed, :available_live, :auto_live_times, :slug, :combined_split_attributes
  link(:self) { api_v1_event_group_path(object) }

  has_many :events
  belongs_to :organization

  def combined_split_attributes
    # Until API clients properly handle location-paired nodes, pair_by_location must be false
    CombineEventGroupSplitAttributes.perform(object, pair_by_location: false)
  end
end
