# frozen_string_literal: true

class AidStationParameters < BaseParameters

  def self.permitted
    [:event_id, :split_id, :status, :open_time, :close_time, :captain_name, :comms_crew_names, :comms_frequencies]
  end
end
