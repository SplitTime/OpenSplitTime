# frozen_string_literal: true

module LotterySimulations
  class RunnerJob < ApplicationJob
    def perform(lottery_simulation_run_id)
      lottery_simulation_run = ::LotterySimulationRun.find(lottery_simulation_run_id)
      ::LotterySimulations::Runner.perform!(lottery_simulation_run)
    end
  end
end
