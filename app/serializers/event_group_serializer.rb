class EventGroupSerializer < BaseSerializer
  attributes :id, :name, :organization_id, :slug, :concealed, :available_live, :auto_live_times
  link(:self) { api_v1_event_group_path(object) }

  has_many :events
  belongs_to :organization

end
