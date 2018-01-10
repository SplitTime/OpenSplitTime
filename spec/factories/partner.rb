FactoryBot.define do
  factory :partner do
    event
    sequence(:name) { |n| "Partner #{n}" }

    trait :with_banner do
      banner_file_name 'test.png'
      banner_content_type 'image/png'
      banner_file_size 1024
      banner_link 'www.partner-site.com'
    end
  end
end
