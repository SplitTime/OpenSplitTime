FactoryGirl.define do
  factory :person do
    first_name { FFaker::Name.first_name }
    last_name { FFaker::Name.last_name }
    gender { FFaker::Gender.random }

    trait :male do
      gender 'male'
    end

    trait :female do
      gender 'female'
    end
  end
end