# frozen_string_literal: true

class AidStationSerializer < BaseSerializer
  attributes :id, :event_id, :split_id, :status, :open_time, :close_time, :captain_name,
             :comms_crew_names, :comms_frequencies
  link(:self) { api_v1_aid_station_path(object) }

  belongs_to :event
  belongs_to :split
end
