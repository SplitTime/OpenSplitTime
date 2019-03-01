FactoryBot.define do
  factory :partner do
    event_group
    sequence(:name) { |n| "Partner #{n}" }

    trait :with_banner do
      banner_link { 'www.partner-site.com' }
      banner { fixture_file_upload(Rails.root.join('spec', 'fixtures', 'files', 'banner.png'), 'image/png') }
    end
  end
end
