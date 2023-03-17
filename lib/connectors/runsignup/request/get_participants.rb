# frozen_string_literal: true

class Connectors::Runsignup::Request::GetParticipants
  BATCH_SIZE = 200

  # @param [String] race_id
  # @param [String] event_id
  # @param [String] page
  def initialize(race_id:, event_id:, page:)
    @race_id = race_id.to_i
    @event_id = event_id.to_i
    @page = page.to_i
  end

  attr_reader :race_id, :event_id, :page

  # @return [String]
  def url_postfix
    "/race/#{race_id}/participants"
  end

  # @return [Hash{Symbol->Symbol | Integer}]
  def specific_params
    {
      event_id: event_id,
      page: page,
      results_per_page: BATCH_SIZE,
      sort: "registration_id ASC",
    }
  end
end
