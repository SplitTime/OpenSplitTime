# frozen_string_literal: true

class LotterySimulationRun < ApplicationRecord
  belongs_to :lottery
  has_many :lottery_simulations
end
