# frozen_string_literal: true

require "rails_helper"

RSpec.describe "User subscribes to an effort's progress notifications", type: :system, js: true do
  let(:user) { users(:third_user) }
  let(:effort) { efforts(:sum_100k_progress_cascade) }

  before { effort.update!(topic_resource_key: "anything") }

  scenario "The user is logged in and subscribes to sms without a phone number" do
    login_as user, scope: :user
    visit effort_path(effort)

    click_link(href: effort_subscriptions_path(effort, subscription: { protocol: :sms }))
    accept_confirm
    expect(page).to have_current_path(user_settings_preferences_path)
    expect(page).to have_content("Please add a mobile phone number to receive sms text notifications.")
  end

  scenario "The user is logged in and subscribes to sms with a phone number" do
    user.update_columns(phone: "1234567890")
    login_as user, scope: :user
    visit effort_path(effort)

    click_link(href: effort_subscriptions_path(effort, subscription: { protocol: :sms }))
    accept_confirm
    expect(page).to have_current_path(effort_path(effort))
    expect(page).to have_content("You have subscribed to sms notifications for #{effort.full_name}.")
  end
end
