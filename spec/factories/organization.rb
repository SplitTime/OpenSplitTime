FactoryBot.define do
  factory :organization do
    name { FFaker::Company.unique.name }
    owner { users(:admin_user) }
  end
end
