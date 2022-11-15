FactoryBot.define do
  factory :lottery_simulation do
    association :simulation_run, class: LotterySimulationRun
  end
end
