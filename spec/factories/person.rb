FactoryBot.define do
  factory :person do
    first_name { FFaker::Name.first_name }
    last_name { FFaker::Name.last_name }
    gender { %w(male female).sample }

    trait :male do
      gender { 'male' }
    end

    trait :female do
      gender { 'female' }
    end

    trait :with_geo_attributes do
      country_code { 'US' }
      state_code { FFaker::AddressUS.state_abbr }
      city { FFaker::AddressUS.city }
    end

    trait :with_birthdate do
      birthdate { FFaker::Time.between(10.years.ago, 80.years.ago).to_date }
    end
  end
end
