FactoryBot.define do
  factory :event_group do
    name { "#{rand(2010..2020)} #{FFaker::Company.name} #{rand(1000)}" }
    organization

    # Samoa causes Capybara to throw ambiguous match errors, so remove it before picking
    home_time_zone { ActiveSupport::TimeZone.all.reject { |timezone| timezone.name == "Samoa" }.sample.name }
  end
end
