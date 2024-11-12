# frozen_string_literal: true

FactoryBot.define do
  factory :course do
    name { "#{FFaker::Product.product} #{rand(1000)}" }
    organization

    trait :with_description do
      description { FFaker::HipsterIpsum.phrase }
    end

    trait :with_splits do
      transient { splits_count { 4 } }
      transient { in_sub_splits_only { false } }
    end

    trait :with_gpx do
      after(:build) do |course|
        course.gpx.attach(
          io: File.open(Rails.root.join("spec", "fixtures", "files", "test_track.gpx")),
          filename: "test_track.gpx",
          content_type: "application/gpx+xml",
        )
      end
    end
  end
end
