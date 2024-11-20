# frozen_string_literal: true

FactoryBot.define do
  factory :historical_fact do
    organization
    first_name { FFaker::Name.first_name }
    last_name { FFaker::Name.last_name }
    birthdate { FFaker::Time.date(years_back: 70, latest_year: 2005) }
    gender { %w[male female].sample }
    kind { "dns" }
  end
end
