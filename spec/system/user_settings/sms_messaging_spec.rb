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

  scenario "disclosure enumerates message contents and omits the old catch-all phrase" do
    login_as user, scope: :user
    visit user_settings_sms_messaging_path

    expect(page).to have_text("name, event, aid station, distance, time of day, and elapsed time")
    expect(page).to have_text("link to view full results")
    expect(page).to have_no_text("related information")
  end

  scenario "carrier-opted-out user sees the warning banner with disabled checkbox" do
    user.update!(phone: "+13038806481", phone_confirmed_at: 2.days.ago, sms_carrier_opted_out_at: 1.hour.ago)
    login_as user, scope: :user
    visit user_settings_sms_messaging_path

    expect(page).to have_text("You replied STOP")
    expect(page).to have_text("text START to +1 (762) 689-8865")
    expect(page).to have_text("ending in 6481")
    expect(page).to have_text("To re-enable SMS, text START")
    expect(page).to have_field("user_sms_consent", disabled: true)
    expect(page).to have_no_text("SMS enabled since")
  end

  scenario "opted-in user without carrier opt-out sees the standard 'enabled since' line" do
    user.update!(phone: "+13038806481", phone_confirmed_at: 5.days.ago)
    login_as user, scope: :user
    visit user_settings_sms_messaging_path

    expect(page).to have_text("SMS enabled since")
    expect(page).to have_no_text("You replied STOP")
    expect(page).to have_field("user_sms_consent", disabled: false)
  end
end
