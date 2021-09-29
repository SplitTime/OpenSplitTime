# frozen_string_literal: true

class LotteryParameters < BaseParameters
  def self.permitted
    [:id, :slug, :name, :scheduled_start_date]
  end
end
