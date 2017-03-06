class EventSerializer < BaseSerializer
  attributes :id, :course_id, :organization_id, :name, :start_time, :concealed, :laps_required, :staging_id
  link(:self) { api_v1_event_path(object) }

  has_many :efforts
  has_many :splits
  belongs_to :course
  belongs_to :organization
end