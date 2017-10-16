FactoryGirl.define do
  factory :user, class: User do
    email { FFaker::Internet.email }
    first_name { FFaker::Name.first_name }
    last_name { FFaker::Name.last_name }
    password '12345678'
    password_confirmation '12345678'
    confirmed_at Date.today
  end

  factory :admin, class: User do
    email { FFaker::Internet.email }
    first_name { FFaker::Name.first_name }
    last_name { FFaker::Name.last_name }
    password '12345678'
    password_confirmation '12345678'
    role :admin
    confirmed_at Date.today
  end
end
