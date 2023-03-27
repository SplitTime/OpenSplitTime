# frozen_string_literal: true

FactoryBot.define do
  factory :credential do
    user
    service_identifier { Connectors::Service::IDENTIFIERS.sample }
    key { FFaker::Product.product }
    value { FFaker::HipsterIpsum.phrase }
  end
end
