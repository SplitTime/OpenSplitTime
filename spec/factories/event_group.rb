FactoryBot.define do
  factory :event_group do
    name { "#{rand(2010..2020)} #{FFaker::Company.name} #{rand(1..10) * 25}" }
    organization
  end
end
