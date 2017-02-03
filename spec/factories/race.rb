FactoryGirl.define do
  factory :race do
    sequence(:name) { |n| "Race #{n}" }
  end
end