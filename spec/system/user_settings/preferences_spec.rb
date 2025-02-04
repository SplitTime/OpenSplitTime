require "rails_helper"

RSpec.describe "user settings preferences", type: :system do
  let(:user) { users(:third_user) }

  scenario "visitor attempts to reach the page" do
    visit user_settings_preferences_path

    expect(page).to have_current_path(root_path)
  end

  scenario "user visits the preferences page" do
    login_as user, scope: :user
    visit user_settings_preferences_path

    expect(page).to have_text("Preferences")
    expect(page).to have_text("Personal Information")
    expect(page).to have_text("Unit Preferences")
  end
end
