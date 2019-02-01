# frozen_string_literal: true

FactoryBot.define do
  factory :effort do
    first_name { FFaker::Name.first_name }
    last_name { FFaker::Name.last_name }
    gender { %w(male female).sample }
    event

    trait :with_geo_attributes do
      country_code { 'US' }
      state_code { FFaker::AddressUS.state_abbr }
      city { FFaker::AddressUS.city }
    end

    trait :with_birthdate do
      birthdate { FFaker::Time.between(10.years.ago, 80.years.ago).to_date }
    end

    trait :with_bib_number do
      sequence(:bib_number, (1..999).to_a.shuffle.cycle)
    end

    trait :with_contact_info do
      email { FFaker::Internet.email }
      phone { FFaker::PhoneNumber.short_phone_number.gsub('-', '') }
    end

    trait :male do
      gender { :male }
    end

    trait :female do
      gender { :female }
    end

    transient { without_slug { false } }

    after(:build, :stub) do |effort, evaluator|
      effort.slug = "#{effort.first_name&.parameterize}-#{effort.last_name&.parameterize}" unless evaluator.without_slug
    end
  end
end
