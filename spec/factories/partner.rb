FactoryBot.define do
  factory :partner do
    event_group
    sequence(:name) { |n| "Partner #{n}" }

    trait :with_banner do
      banner_link { "www.partner-site.com" }
      banner { ::Rack::Test::UploadedFile.new("spec/fixtures/files/banner.png", "image/png") }
    end
  end
end
