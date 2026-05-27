FactoryBot.define do
  factory :organization do
    name { FFaker::Company.unique.name }
    owner_id { ActiveRecord::FixtureSet.identify(:admin_user) }
  end
end
