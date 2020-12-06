# frozen_string_literal: true

require "rails_helper"

RSpec.describe "User logs in with modal google", js: true do
  after { OmniAuth.config.mock_auth[:google_oauth2] = nil }
  let(:provider) { "google_oauth2" }
  let(:uid) { "123456" }

  context "with valid credentials" do
    before do
      OmniAuth.config.mock_auth[:google_oauth2] =
        OmniAuth::AuthHash.new(
          provider: provider,
          uid: uid,
          info: {
            first_name: user.first_name,
            last_name: user.last_name,
            email: user.email
          }
        )
    end

    context "for a user that does not exist in the database" do
      let(:user) { build(:user, first_name: "First", last_name: "Last", email: "name@example.com") }

      scenario "user attempts to log in" do
        visit organizations_path

        login_with_google
        verify_valid
        verify_user_exists(user.email)
      end
    end

    context "for a user that already exists in the database" do
      let(:user) { users(:admin_user) }

      scenario "user attempts to log in" do
        visit organizations_path

        login_with_google
        verify_valid
        verify_user_exists(user.email)
      end
    end
  end

  context "with invalid credentials" do
    before { OmniAuth.config.mock_auth[:google_oauth2] = :invalid_credentials }

    scenario "user attempts to log in" do
      visit organizations_path

      login_with_google
      verify_invalid
    end
  end

  def login_with_google
    within(".navbar") do
      click_link "Log In"
    end

    within("#log-in-modal") do
      click_link "google-log-in-button"
    end
  end

  def verify_valid
    expect(page).to have_content(user.email)
    expect(page).to have_current_path(organizations_path)
  end

  def verify_user_exists(email)
    user = User.find_by(email: email)
    expect(user).to be_present
    expect(user.provider).to eq(provider)
    expect(user.uid).to eq(uid)
  end

  def verify_invalid
    expect(page).to have_content(:all, "Could not authenticate you from Google")
    expect(page).to have_current_path(new_user_registration_path)
  end
end
