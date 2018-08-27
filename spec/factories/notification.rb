# frozen_string_literal: true

FactoryBot.define do
  factory :notification do
    effort
    distance { rand(1000..100_000) }
    bitkey { [1, 64].sample }
  end
end
