# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Visitor signs up' do
  scenario 'with valid first_name, last_name, email, and password' do
    sign_up_with 'Joe', 'Example', 'valid@example.com', 'password'

    expect(page).to have_content(:all, 'A message with a confirmation link has been sent to your email address.')
  end

  scenario 'without first name' do
    sign_up_with '', 'Example', 'valid@example.com', 'password'

    expect(page).to have_content(:all, "First name can't be blank")
  end

  scenario 'without last name' do
    sign_up_with 'Joe', '', 'valid@example.com', 'password'

    expect(page).to have_content(:all, "Last name can't be blank")
  end

  scenario 'with invalid email' do
    sign_up_with 'Joe', 'Example', 'invalid_email', 'password'

    expect(page).to have_content(:all, 'Email is invalid')
  end

  scenario 'with invalid phone number' do
    sign_up_with 'Joe', 'Example', 'valid@example.com', 'password', '1234'

    expect(page).to have_content(:all, 'Phone must be a valid US or Canada phone number')
  end

  scenario 'with blank password' do
    sign_up_with 'Joe', 'Example', 'valid@example.com', ''

    expect(page).to have_content(:all, "Password can't be blank")
  end

  scenario 'with too short password' do
    sign_up_with 'Joe', 'Example', 'valid@example.com', '1234'

    expect(page).to have_content(:all, "Password is too short")
  end

  def sign_up_with(first_name, last_name, email, password, phone = nil)
    visit new_user_registration_path
    fill_in 'First name', with: first_name
    fill_in 'Last name', with: last_name
    fill_in 'Email', with: email
    fill_in 'US or Canada mobile number', with: phone
    fill_in 'Password*', with: password
    fill_in 'Password confirmation*', with: password
    click_button 'Sign up'
  end
end
