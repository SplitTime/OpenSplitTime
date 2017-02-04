FactoryGirl.define do
  factory :race do
    sequence(:name) { |n| "Organization #{n}" }
  end
end