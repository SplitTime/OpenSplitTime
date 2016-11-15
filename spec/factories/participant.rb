FactoryGirl.define do
  factory :participant do
    first_name 'Joe'
    sequence(:last_name) { |n| "LastName #{n}" }
    gender 'male'
  end
end