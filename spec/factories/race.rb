FactoryGirl.define do
  factory :organization do
    sequence(:name) { |n| "Organization #{n}" }
  end
end