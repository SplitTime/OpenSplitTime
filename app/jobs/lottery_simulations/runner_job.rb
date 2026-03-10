module LotterySimulations
  class RunnerJob < ApplicationJob
    queue_as :default

    def perform(lottery_simulation_run_id)
      lottery_simulation_run = ::LotterySimulationRun.find(lottery_simulation_run_id)
      ::LotterySimulations::Runner.perform!(lottery_simulation_run)
    end
  end
end
