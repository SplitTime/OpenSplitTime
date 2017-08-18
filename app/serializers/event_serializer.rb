class EventSerializer < BaseSerializer
  attributes :id, :course_id, :organization_id, :name, :start_time, :home_time_zone, :concealed,
             :laps_required, :staging_id, :maximum_laps, :multi_lap, :slug, :live_entry_attributes
  link(:self) { api_v1_event_path(object) }

  has_many :efforts
  has_many :splits
  has_many :aid_stations
  belongs_to :course
  belongs_to :organization

  def multi_lap
    object.multiple_laps?
  end
end
