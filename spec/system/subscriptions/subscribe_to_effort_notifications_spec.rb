require "rails_helper"

RSpec.describe "User subscribes to an effort's progress notifications", :js, type: :system do
  include ActionView::RecordIdentifier

  let(:user) { users(:third_user) }
  let(:admin) { users(:admin_user) }
  let(:effort) { efforts(:sum_100k_progress_cascade) }

  before { effort.update!(topic_resource_key: "anything") }

  scenario "The user is not logged in and subscribes to sms" do
    pending "SMS is admin-only pending 10DLC campaign approval"
    visit_page

    page.accept_confirm("You must be signed in to subscribe to notifications") do
      within("##{dom_id(effort, :sms)}") { click_button("sms") }
    end

    expect(page).to have_current_path(effort_path(effort))
  end

  scenario "The user is not logged in and subscribes to email" do
    visit_page

    page.accept_confirm("You must be signed in to subscribe to notifications") do
      within("##{dom_id(effort, :email)}") { click_button("email") }
    end

    expect(page).to have_current_path(effort_path(effort))
  end

  scenario "The user is logged in and subscribes to email" do
    login_as user, scope: :user
    visit_page

    accept_confirm do
      within("##{dom_id(effort, :email)}") { click_button("email") }
    end
    expect(page).to have_current_path(effort_path(effort))
    expect(page).to have_content("You have subscribed to email notifications for #{effort.full_name}.")
  end

  scenario "The user is logged in and subscribes to sms without a phone number" do
    pending "SMS is admin-only pending 10DLC campaign approval"
    login_as user, scope: :user
    visit_page

    within("##{dom_id(effort, :sms)}") { click_button("sms") }
    accept_confirm
    expect(page).to have_current_path(user_settings_preferences_path)
    expect(page).to have_content("Please add a mobile phone number to receive sms text notifications.")
  end

  scenario "The user is logged in and subscribes to sms with a phone number" do
    pending "SMS is admin-only pending 10DLC campaign approval"
    user.update_columns(phone: "1234567890")
    login_as user, scope: :user
    visit_page

    within("##{dom_id(effort, :sms)}") { click_button("sms") }
    accept_confirm
    expect(page).to have_current_path(effort_path(effort))
    expect(page).to have_content("You have subscribed to sms notifications for #{effort.full_name}.")
  end

  scenario "Non-admin user sees SMS out of service message" do
    login_as user, scope: :user
    visit_page

    expect(page).to have_content("SMS temporarily out of service")
  end

  scenario "Admin without SMS opt-in sees Enable SMS link" do
    admin.update_columns(phone_confirmed_at: nil)
    login_as admin, scope: :user
    visit_page

    within("##{dom_id(effort, :sms)}") do
      expect(page).to have_link("Enable SMS")
    end
  end

  scenario "Admin with SMS opt-in sees SMS subscribe button" do
    login_as admin, scope: :user
    visit_page

    within("##{dom_id(effort, :sms)}") do
      expect(page).to have_button("sms")
    end
  end

  def visit_page
    visit effort_path(effort)
  end
end
