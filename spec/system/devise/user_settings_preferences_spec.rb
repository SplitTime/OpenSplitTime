require "rails_helper"

RSpec.describe "visit the user settings preferences page and make changes", type: :system, js: true do
  let(:user) { users(:third_user) }

  scenario "The user is a visitor" do
    visit_page
    expect(page).to have_current_path(root_path)
    verify_alert("You need to sign in or sign up before continuing")
  end

  scenario "A logged in user changes personal information" do
    login_as user, scope: :user

    visit_page
    expect(page).to have_current_path(user_settings_preferences_path)
    expect(page).to have_field("First name", with: user.first_name)
    expect(page).to have_field("Last name", with: user.last_name)

    fill_in "First name", with: "John"
    fill_in "Last name", with: "Doe"
    fill_in "user_phone", with: "555-555-5555"

    click_button "Save Changes"

    expect(page).to have_current_path(user_settings_preferences_path)
    expect(page).to have_field("First name", with: "John")
    expect(page).to have_field("Last name", with: "Doe")
    user.reload
    expect(user.first_name).to eq("John")
    expect(user.last_name).to eq("Doe")
    expect(user.phone).to eq("+15555555555")
  end

  def visit_page
    visit user_settings_preferences_path
  end
end
