# frozen_string_literal: true

class Connectors::RattlesnakeRamble::FetchRaceEntries
  # @param [String] race_edition_id
  # @param [User] user
  # @param [::Connectors::RattlesnakeRamble::Client, nil] client
  # @return [Array<::Connectors::RattlesnakeRamble::Models::RaceEntry>]
  def self.perform(race_edition_id:, user:, client: nil)
    new(race_edition_id: race_edition_id, user: user, client: client).perform
  end

  # @param [String] race_edition_id
  # @param [User] user
  # @param [::Connectors::RattlesnakeRamble::Client, nil] client
  def initialize(race_edition_id:, user:, client: nil)
    @race_edition_id = race_edition_id
    @client = client || ::Connectors::RattlesnakeRamble::Client.new(user)
    @race_entries = []
  end

  # @return [Array<::Connectors::RattlesnakeRamble::Models::RaceEntry>]
  def perform
    body = client.get_race_edition(race_edition_id)
    parsed_body = JSON.parse(body)

    raw_race_entries = parsed_body.dig("race_entries")
    raw_race_entries.each do |raw_race_entry| race_entries << race_entry_from_raw(raw_race_entry)
    end

    race_entries
  end

  private

  attr_reader :race_edition_id, :client, :race_entries

  # @param [Hash] raw_race_entry
  # @return [::Connectors::RattlesnakeRamble::Models::Event]
  def race_entry_from_raw(raw_race_entry)
    raw_racer = raw_race_entry.delete("racer")

    race_entry = ::Connectors::RattlesnakeRamble::Models::RaceEntry.new(raw_race_entry)
    race_entry.racer = ::Connectors::RattlesnakeRamble::Models::Racer.new(raw_racer)
    race_entry
  end
end
