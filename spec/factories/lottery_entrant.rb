FactoryBot.define do
  factory :lottery_entrant do
    association :division, factory: :lottery_division
    first_name { FFaker::Name.first_name }
    last_name { FFaker::Name.last_name }
    gender { %w[male female].sample }
    number_of_tickets { 1 }
  end
end
