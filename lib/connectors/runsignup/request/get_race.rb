class Connectors::Runsignup::Request::GetRace
  # @param [String] race_id
  def initialize(race_id:)
    @race_id = race_id
  end

  attr_reader :race_id

  # @return [String]
  def url_postfix
    "/race/#{race_id}"
  end

  # @return [Hash]
  def specific_params
    {}
  end
end
