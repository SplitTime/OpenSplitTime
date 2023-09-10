# frozen_string_literal: true

class Connectors::RattlesnakeRamble::Request::GetRaceEdition
  # @param [String] race_edition_id
  def initialize(race_edition_id:)
    @race_edition_id = race_edition_id.to_i
  end

  attr_reader :race_edition_id

  # @return [String]
  def url_postfix
    "/race_editions/#{race_edition_id}"
  end

  # @return [Hash{Symbol->Symbol | Integer}]
  def specific_params
    {}
  end
end
