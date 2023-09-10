# frozen_string_literal: true

class Connectors::RattlesnakeRamble::FetchRaceEditions
  # @param [User] user
  # @param [::Connectors::RattlesnakeRamble::Client, nil] client
  # @return [Array<::Connectors::RattlesnakeRamble::Models::Event>]
  def self.perform(user:, client: nil)
    new(user: user, client: client).perform
  end

  # @param [User] user
  # @param [::Connectors::RattlesnakeRamble::Client, nil] client
  def initialize(user:, client: nil)
    @client = client || ::Connectors::RattlesnakeRamble::Client.new(user)
    @race_editions = []
  end

  # @return [Array<::Connectors::RattlesnakeRamble::Models::RaceEdition>]
  def perform
    body = client.get_race_editions
    parsed_body = JSON.parse(body)

    raw_race_editions = parsed_body
    raw_race_editions.each { |raw_race_edition| race_editions << race_edition_from_raw(raw_race_edition) }

    race_editions
  end

  private

  attr_reader :race_id, :client, :race_editions

  # @param [Hash] raw_race_edition
  # @return [::Connectors::RattlesnakeRamble::Models::RaceEdition]
  def race_edition_from_raw(raw_race_edition)
    ::Connectors::RattlesnakeRamble::Models::RaceEdition.new(raw_race_edition)
  end
end
