# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'User logs in with modal', js: true do
  let(:user) { users(:admin_user) }
  let(:email) { user.email }
  let(:password) { 'password' }

  let(:invalid_email) { 'joe@example.com' }
  let(:invalid_password) { '11111111' }

  scenario 'with valid email and password' do
    visit organizations_path

    login_with_modal(email, password)
    verify_valid
  end

  scenario 'with invalid email' do
    visit organizations_path

    login_with_modal(invalid_email, password)
    verify_invalid
  end

  scenario 'with invalid password' do
    visit organizations_path

    login_with_modal(email, invalid_password)
    verify_invalid
  end

  def login_with_modal(email, password)
    within('.navbar') do
      click_link 'Log In'
    end

    within('#log-in-modal') do
      fill_in 'Email', with: email
      fill_in 'Password', with: password
      click_button 'Log in'
    end
  end

  def verify_valid
    expect(page).to have_content(user.email)
    expect(page).to have_current_path(organizations_path)
  end

  def verify_invalid
    expect(page).to have_content(:all, 'Invalid email or password')
    expect(page).to have_current_path(organizations_path)
  end
end
