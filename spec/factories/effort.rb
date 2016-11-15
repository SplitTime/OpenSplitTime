FactoryGirl.define do
  factory :effort do
    first_name 'Joe'
    sequence(:last_name) { |n| "LastName #{n}" }
    gender 'male'
    start_offset 0
    event
    participant
  end
end