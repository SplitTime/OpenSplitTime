# frozen_string_literal: true

FactoryBot.define do
  factory :event do
    name { "#{rand(2010..2020)} #{FFaker::Company.name} #{rand(1..10) * 25}" }

    # Samoa causes Capybara to throw ambiguous match errors, so remove it before picking

    home_time_zone { ActiveSupport::TimeZone.all.reject { |timezone| timezone.name == 'Samoa' }.shuffle.first.name }
    start_time { FFaker::Time.datetime }
    laps_required { 1 }
    course
    event_group

    transient { without_slug { false } }

    after(:build, :stub) do |event, evaluator|
      event.slug = event.name.parameterize unless evaluator.without_slug
    end
  end
end
