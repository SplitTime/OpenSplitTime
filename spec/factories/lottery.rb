FactoryBot.define do
  factory :lottery do
    name { FFaker::Product.product }
    scheduled_start_date { Date.current }
    organization
  end
end
