FactoryBot.define do
  factory :organization do
    name { FFaker::Company.unique.name }
    owner_id { 1 }
  end
end
