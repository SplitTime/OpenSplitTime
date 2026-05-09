require "rails_helper"

RSpec.describe "User subscribes to notifications for a person", :js, type: :system do
  include ActionView::RecordIdentifier

  let(:user) { users(:third_user) }
  let(:person) { people(:progress_cascade) }

  before { person.update!(topic_resource_key: "anything") }

  scenario "Anonymous user sees the email subscribe CTA as a link into the login modal frame" do
    visit_page

    within("##{dom_id(person, :email)}") do
      expect(page).to have_link(href: %r{/users/sign_in\?.*notification_protocol=email})
    end
  end

  scenario "The user is logged in and subscribes to email" do
    login_as user, scope: :user
    visit_page

    accept_confirm do
      within("##{dom_id(person, :email)}") { click_button("email") }
    end

    expect(page).to have_current_path(person_path(person))
    expect(page).to have_content("You have subscribed to email notifications for #{person.full_name}.")
  end

  scenario "No SMS subscription option is offered for person subscriptions" do
    login_as user, scope: :user
    visit_page

    expect(page).to have_no_css("##{dom_id(person, :sms)}")
    expect(page).to have_no_link(href: %r{/user_settings/sms_messaging})
  end

  def visit_page
    visit person_path(person)
  end
end
