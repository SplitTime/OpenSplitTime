# frozen_string_literal: true

require "rails_helper"

RSpec.describe "User subscribes to notifications for a person", type: :system, js: true do
  include ActionView::RecordIdentifier

  let(:user) { users(:third_user) }
  let(:person) { people(:progress_cascade) }

  before { person.update!(topic_resource_key: "anything") }

  scenario "The user is not logged in and subscribes to email" do
    visit_page

    within("##{dom_id(person, :email)}") { click_button("email") }
    page.accept_confirm("You must be signed in to subscribe to notifications")
    expect(page).to have_current_path(person_path(person))
  end

  scenario "The user is not logged in and subscribes to sms" do
    visit_page

    within("##{dom_id(person, :sms)}") { click_button("sms") }
    page.accept_confirm("You must be signed in to subscribe to notifications")
    expect(page).to have_current_path(person_path(person))
  end

  scenario "The user is logged in and subscribes to email" do
    login_as user, scope: :user
    visit_page

    within("##{dom_id(person, :email)}") { click_button("email") }
    accept_confirm
    expect(page).to have_current_path(person_path(person))
    expect(page).to have_content("You have subscribed to email notifications for #{person.full_name}.")
  end

  scenario "The user is logged in and subscribes to sms without a phone number" do
    login_as user, scope: :user
    visit_page

    within("##{dom_id(person, :sms)}") { click_button("sms") }
    accept_confirm
    expect(page).to have_current_path(user_settings_preferences_path)
    expect(page).to have_content("Please add a mobile phone number to receive sms text notifications.")
  end

  scenario "The user is logged in and subscribes to sms with a phone number" do
    user.update_columns(phone: "1234567890")
    login_as user, scope: :user
    visit_page

    within("##{dom_id(person, :sms)}") { click_button("sms") }
    accept_confirm
    expect(page).to have_current_path(person_path(person))
    expect(page).to have_content("You have subscribed to sms notifications for #{person.full_name}.")
  end

  def visit_page
    visit person_path(person)
  end
end
