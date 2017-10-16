FactoryGirl.define do
  factory :organization do
    name { FFaker::Company.name }
  end
end
