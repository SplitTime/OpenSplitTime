require "rails_helper"

RSpec.describe "User logs in with modal facebook", js: true do
  after { OmniAuth.config.mock_auth[:facebook] = nil }
  let(:provider) { "facebook" }
  let(:uid) { "123456" }

  context "with valid credentials" do
    before do
      OmniAuth.config.mock_auth[:facebook] =
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

        login_with_facebook
        verify_valid
        verify_user_exists(user.email)
      end
    end

    context "for a user that already exists in the database" do
      let(:user) { users(:admin_user) }

      scenario "user attempts to log in" do
        visit organizations_path

        login_with_facebook
        verify_valid
        verify_user_exists(user.email)
      end
    end
  end

  context "with invalid credentials" do
    before { OmniAuth.config.mock_auth[:facebook] = :invalid_credentials }

    scenario "user attempts to log in" do
      visit organizations_path

      login_with_facebook
      verify_invalid
    end
  end

  def login_with_facebook
    within(".navbar") do
      click_link "Log In"
    end

    within("#form_modal") do
      click_button "facebook-log-in-button"
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
    expect(page).to have_content(:all, "Could not authenticate you from Facebook")
    expect(page).to have_current_path(new_user_registration_path)
  end
end
