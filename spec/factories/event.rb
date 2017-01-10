FactoryGirl.define do
  factory :event do
    sequence(:name) { |n| "Test Event #{n}" }
    start_time '2016-07-01 06:00:00'
    course
  end
end