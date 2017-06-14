FactoryGirl.define do
  factory :partner_ad do
    event
    banner_file_name 'test.png'
    banner_content_type 'image/png'
    banner_file_size 1024
    link 'www.partnersite.com'
    weight 1
  end
end
