# frozen_string_literal: true

FactoryBot.define do
  factory :split_time do
    absolute_time { Date.today.at_midnight + rand(-100_000..100_000) }
    effort
    lap { 1 }
    bitkey { 1 }
  end
end
