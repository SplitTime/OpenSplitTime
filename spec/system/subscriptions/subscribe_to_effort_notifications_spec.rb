require "rails_helper"

RSpec.describe "User subscribes to an effort's progress notifications", :js, type: :system do
  include ActionView::RecordIdentifier

  let(:user) { users(:third_user) }
  let(:effort) { efforts(:sum_100k_progress_cascade) }

  before { effort.update!(topic_resource_key: "anything") }

  scenario "Anonymous user sees the email subscribe CTA as a link into the login modal frame carrying the subscribe intent" do
    visit_page

    within("##{dom_id(effort, :email)}") do
      expect(page).to have_link(href: %r{/users/sign_in\?.*notification_protocol=email})
    end
  end

  scenario "Anonymous user sees the SMS subscribe CTA as a link into the login modal frame carrying the subscribe intent" do
    visit_page

    within("##{dom_id(effort, :sms)}") do
      expect(page).to have_link(href: %r{/users/sign_in\?.*notification_protocol=sms})
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

  scenario "Anonymous user clicking the SMS subscribe CTA opens the login modal with the warning message and a working form" do
    visit_page

    within("##{dom_id(effort, :sms)}") { click_link("text") }

    within("#form_modal") do
      expect(page).to have_content(I18n.t("subscriptions.toggle.sign_in_required"))
      expect(page).to have_field("Email")
      expect(page).to have_field("Password")
      expect(page).to have_button("Log in")
    end
  end

  scenario "Anonymous user clicks email subscribe, logs in via the modal, and the email subscription is auto-created" do
    admin = users(:admin_user)

    visit_page

    within("##{dom_id(effort, :email)}") { click_link("email") }

    within("#form_modal") do
      fill_in "Email", with: admin.email
      fill_in "Password", with: "password"
      click_button "Log in"
    end

    expect(page).to have_current_path(effort_path(effort))
    expect(page).to have_content(admin.email)
    expect(admin.subscriptions.where(subscribable: effort, protocol: :email)).to exist

    within("##{dom_id(effort, :email)}") do
      expect(page).to have_css("button.email-sub.btn-primary")
    end
  end

  scenario "Anonymous user clicks SMS subscribe, logs in via the modal as a not-opted-in user, lands on the SMS settings page" do
    admin = users(:admin_user)
    admin.update!(phone: nil, phone_confirmed_at: nil)

    visit_page

    within("##{dom_id(effort, :sms)}") { click_link("text") }

    within("#form_modal") do
      fill_in "Email", with: admin.email
      fill_in "Password", with: "password"
      click_button "Log in"
    end

    # The visit-stream from the SessionsController hands off to the streamlined
    # SMS opt-in flow: lands on /user_settings/sms_messaging with subscribe_to
    # carried over so saving phone+consent there will create the subscription.
    expect(page).to have_current_path(/\A#{Regexp.escape(user_settings_sms_messaging_path)}\?subscribe_to=/)
    expect(page).to have_field("Phone")
  end

  scenario "Anonymous user clicks SMS subscribe, logs in as a not-opted-in user, completes phone+consent, and ends up subscribed on the effort" do
    admin = users(:admin_user)
    admin.update!(phone: nil, phone_confirmed_at: nil)

    visit_page

    # Step 1: anonymous click on SMS "text" subscribe -> login modal opens.
    within("##{dom_id(effort, :sms)}") { click_link("text") }

    # Step 2: log in inside the modal.
    within("#form_modal") do
      fill_in "Email", with: admin.email
      fill_in "Password", with: "password"
      click_button "Log in"
    end

    # Step 3: SessionsController#create hands off to the streamlined SMS opt-in
    # flow because admin isn't sms_opted_in?. Lands on the SMS settings page
    # carrying subscribe_to (re-encoded for the sms_opt_in_subscribe purpose).
    expect(page).to have_current_path(/\A#{Regexp.escape(user_settings_sms_messaging_path)}\?subscribe_to=/)

    # Step 4: page-load warning explains what's still missing for this specific
    # subscribable. (Proves the SGID decoded successfully on this side — if the
    # purpose mismatch hadn't been fixed, pending_subscribable would be nil and
    # this warning wouldn't render.)
    expect(page).to have_content(I18n.t("sms.consent.subscribe_pending_phone_and_consent", name: effort.full_name))

    # Step 5: fill in phone + consent and save.
    fill_in "Phone", with: "303-555-1212"
    check "user_sms_consent"
    click_button "Save Changes"

    # Step 6: streamlined opt-in flow completes — back on the effort page,
    # both flashes set, SMS subscription created.
    expect(page).to have_current_path(effort_path(effort))
    expect(page).to have_content(I18n.t("sms.consent.opted_in"))
    expect(page).to have_content("You have subscribed to sms notifications for #{effort.full_name}")
    expect(admin.subscriptions.where(subscribable: effort, protocol: :sms)).to exist
  end

  def visit_page
    visit effort_path(effort)
  end
end
