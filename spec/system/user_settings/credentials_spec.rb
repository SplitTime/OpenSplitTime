require "rails_helper"

RSpec.describe "user settings preferences", type: :system, js: true do
  let(:user) { users(:third_user) }

  scenario "visitor attempts to reach the page" do
    visit user_settings_credentials_path

    expect(page).to have_current_path(root_path)
  end

  scenario "user visits the preferences page" do
    login_as user, scope: :user
    visit user_settings_credentials_path

    expect(page).to have_text("Add Credentials")
    within("#credentials_list") do
      within(first(".card")) do
        expect(page).to have_text("RunSignup")
        expect(page).to have_button("Reveal")

        expect(page).not_to have_text("api_key")
        expect(page).not_to have_text("api_secret")

        click_button("Reveal")

        expect(page).to have_text("api_key")
        expect(page).to have_text("api_secret")

        click_button("Hide")

        expect(page).not_to have_text("api_key")
        expect(page).not_to have_text("api_secret")
      end
    end
  end
end
