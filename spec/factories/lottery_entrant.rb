FactoryBot.define do
  factory :lottery_entrant do
    association :division, factory: :lottery_division
  end
end
