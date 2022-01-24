# frozen_string_literal: true

class LotterySimulationRunParameters < BaseParameters
  def self.permitted
    [
      :requested_count,
    ]
  end
end
