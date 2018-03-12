# frozen_string_literal: true

class EventSerializer < BaseSerializer
  attributes :id, :course_id, :organization_id, :name, :start_time, :home_time_zone, :start_time_in_home_zone, :concealed,
             :laps_required, :maximum_laps, :multi_lap, :monitor_pacers, :slug, :short_name, :live_entry_attributes, :multiple_sub_splits
  link(:self) { api_v1_event_path(object) }

  has_many :efforts
  has_many :splits
  has_many :aid_stations
  belongs_to :course
  belongs_to :event_group

  def multi_lap
    object.multiple_laps?
  end

  def concealed
    object.event_group.concealed?
  end

  def multiple_sub_splits
    object.multiple_sub_splits?
  end
end
