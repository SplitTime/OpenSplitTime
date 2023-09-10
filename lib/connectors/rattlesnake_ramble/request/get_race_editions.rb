# frozen_string_literal: true

class Connectors::RattlesnakeRamble::Request::GetRaceEditions
  # @return [String]
  def url_postfix
    "/race_editions"
  end

  # @return [Hash]
  def specific_params
    {}
  end
end
