class EventGroupSerializer < BaseSerializer
  attributes :id, :name, :organization_id, :concealed, :available_live, :auto_live_times, :slug, :combined_split_attributes
  link(:self) { api_v1_event_group_path(object) }

  has_many :events
  belongs_to :organization

  def combined_split_attributes
    CombineEventGroupSplitAttributes.perform(object)
  end
end
