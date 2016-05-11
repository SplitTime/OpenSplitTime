FactoryGirl.define do
  sequence :email do |n|
    "person#{n}@example.com"
  end

  sequence :first_name do |n|
    "User#{n}"
  end
end

FactoryGirl.define do
  factory :user, :class => 'User' do
    email
    first_name
    last_name 'Normal'
    password '12345678'
    password_confirmation '12345678'
    confirmed_at Date.today
  end

  factory :admin, class: 'User' do
    email
    first_name
    last_name 'Admin'
    password '12345678'
    password_confirmation '12345678'
    role 'admin'
    confirmed_at Date.today
  end
end
