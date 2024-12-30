FactoryBot.define do
  factory :lottery_division do
    association :lottery
    name { "Division A" }
    maximum_entries { 10 }
    maximum_wait_list { 10 }
  end
end
