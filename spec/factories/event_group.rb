FactoryGirl.define do
  factory :event_group do
    sequence(:name) { |n| "Event Group #{n}" }
    organization
  end
end