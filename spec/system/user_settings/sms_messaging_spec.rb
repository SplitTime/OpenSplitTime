require "rails_helper"

RSpec.describe "user settings sms messaging", type: :system do
  let(:user) { users(:third_user) }

  scenario "visitor attempts to reach the page" do
    visit user_settings_sms_messaging_path

    expect(page).to have_current_path(root_path)
  end

  scenario "user visits the SMS Messaging page" do
    login_as user, scope: :user
    visit user_settings_sms_messaging_path

    expect(page).to have_text("SMS Messaging")
    expect(page).to have_text("strictly optional")
    expect(page).to have_field("Phone")
    expect(page).to have_field("user_sms_consent")
  end
end
