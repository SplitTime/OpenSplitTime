# frozen_string_literal: true

class LotteryParameters < BaseParameters
  def self.permitted
    [
      :id,
      :name,
      :scheduled_start_date,
      :slug,
    ]
  end

  def self.permitted_query
    permitted + LotteryEntrantParameters.permitted
  end
end
