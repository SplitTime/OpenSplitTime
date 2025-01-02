FactoryBot.define do
  factory :historical_fact do
    organization
    first_name { FFaker::Name.first_name }
    last_name { FFaker::Name.last_name }
    gender { %w[male female].sample }
    kind { "dns" }

    trait :with_birthdate do
      birthdate { FFaker::Time.date(years_back: 70, latest_year: 2005) }
    end
  end
end
