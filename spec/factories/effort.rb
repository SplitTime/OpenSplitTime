FactoryGirl.define do
  factory :effort do
    first_name 'Joe'
    last_name 'Hardman'
    gender 'male'
    start_offset 0
    event
    participant
  end
end