class Connectors::Runsignup::FetchRaceEvents
  # @param [String] race_id
  # @param [User] user
  # @param [::Connectors::Runsignup::Client, nil] client
  # @return [Array<::Connectors::Runsignup::Models::Event>]
  def self.perform(race_id:, user:, client: nil)
    new(race_id: race_id, user: user, client: client).perform
  end

  # @param [String] race_id
  # @param [User] user
  # @param [::Connectors::Runsignup::Client, nil] client
  def initialize(race_id:, user:, client: nil)
    @race_id = race_id
    @client = client || ::Connectors::Runsignup::Client.new(user)
    @events = []
  end

  # @return [Array<::Connectors::Runsignup::Models::Event>]
  def perform
    body = client.get_race(race_id)
    parsed_body = JSON.parse(body)

    raw_events = parsed_body.dig("race", "events")
    raw_events.each { |raw_event| events << event_from_raw(raw_event) }

    events
  end

  private

  attr_reader :race_id, :client, :events

  # @param [Hash] raw_event
  # @return [::Connectors::Runsignup::Models::Event]
  def event_from_raw(raw_event)
    ::Connectors::Runsignup::Models::Event.new(
      id: raw_event["event_id"],
      name: raw_event["name"],
      start_time: raw_event["start_time"],
      end_time: raw_event["end_time"],
    )
  end
end
