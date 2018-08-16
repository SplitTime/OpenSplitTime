# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'User logs in' do
  let!(:user) { create(:user, email: email, password: password, password_confirmation: password) }
  let(:email) { 'jane@example.com' }
  let(:password) { '12345678' }

  let(:invalid_email) { 'joe@example.com' }
  let(:invalid_password) { '11111111' }

  scenario 'with valid email and password' do
    login_with(email, password)
    expect(page).to have_content('You are signed in.')
  end

  scenario 'with invalid email' do
    login_with(invalid_email, password)
    expect(page).to have_content('Invalid email or password')
  end

  scenario 'with invalid password' do
    login_with(email, invalid_password)
    expect(page).to have_content('Invalid email or password')
  end

  def login_with(email, password)
    visit new_user_session_path
    fill_in 'Email', with: email
    fill_in 'Password', with: password
    click_button 'Sign in'
  end
end
