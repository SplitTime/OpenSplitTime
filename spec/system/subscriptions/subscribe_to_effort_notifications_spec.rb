require "rails_helper"

RSpec.describe "User subscribes to an effort's progress notifications", :js, type: :system do
  include ActionView::RecordIdentifier

  let(:user) { users(:third_user) }
  let(:effort) { efforts(:sum_100k_progress_cascade) }

  before { effort.update!(topic_resource_key: "anything") }

  scenario "Anonymous user sees the email subscribe CTA as a link into the login modal frame" do
    visit_page

    within("##{dom_id(effort, :email)}") do
      expect(page).to have_link(href: new_user_session_path(reason: "subscribe"))
    end
  end

  scenario "Anonymous user sees the SMS subscribe CTA as a link into the login modal frame" do
    visit_page

    within("##{dom_id(effort, :sms)}") do
      expect(page).to have_link(href: new_user_session_path(reason: "subscribe"))
    end
  end

  scenario "The logged-in user subscribes to email" do
    login_as user, scope: :user
    visit_page

    accept_confirm do
      within("##{dom_id(effort, :email)}") { click_button("email") }
    end
    expect(page).to have_current_path(effort_path(effort))
    expect(page).to have_content("You have subscribed to email notifications for #{effort.full_name}.")
  end

  scenario "Logged-in user without SMS opt-in sees the opt-in link in the SMS frame" do
    login_as user, scope: :user
    visit_page

    within("##{dom_id(effort, :sms)}") do
      expect(page).to have_link(href: %r{/user_settings/sms_messaging})
    end
  end

  scenario "Logged-in user with SMS opt-in sees the SMS subscribe button" do
    user.update!(phone: "+13035551212", phone_confirmed_at: 1.day.ago)
    login_as user, scope: :user
    visit_page

    within("##{dom_id(effort, :sms)}") do
      expect(page).to have_button("text")
    end
  end

  def visit_page
    visit effort_path(effort)
  end
end
