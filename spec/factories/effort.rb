FactoryGirl.define do
  factory :effort do
    first_name 'Joe'
    sequence(:last_name) { |n| "LastName #{n}" }
    gender 'male'
    start_offset 0
    event
    participant
  end

  factory :efforts_hardrock, class: Effort do
    sequence(:id, (100..109).cycle)
    first_name 'Joe'
    sequence(:last_name) { |n| "LastName #{n}" }
    gender 'male'
    start_offset 0
    event
    participant
  end
end