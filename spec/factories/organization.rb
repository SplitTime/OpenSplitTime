FactoryBot.define do
  factory :organization do
    name { FFaker::Company.name }
    owner_id { 1 }
  end
end
