FactoryBot.define do
  factory :lottery_simulation_run do
    lottery
    requested_count { 2 }
  end
end
