# frozen_string_literal: true

FactoryBot.define do
  factory :event do
    start_time { FFaker::Time.datetime }
    laps_required { 1 }
    course
    event_group

    trait :with_short_name do
      short_name { "#{rand(25..200)}#{%w(-mile -kilo k M).sample}" }
    end

    transient { without_slug { false } }

    after(:build, :stub) do |event, evaluator|
      event.slug = event.name.parameterize unless evaluator.without_slug
    end
  end
end
