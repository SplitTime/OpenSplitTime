require "rails_helper"

RSpec.describe "User subscribes to notifications for a person", :js, type: :system do
  include ActionView::RecordIdentifier

  let(:user) { users(:third_user) }
  let(:person) { people(:progress_cascade) }

  before { person.update!(topic_resource_key: "anything") }

  scenario "The user is not logged in and subscribes to email" do
    visit_page

    page.accept_confirm("You must be signed in to subscribe to notifications") do
      within("##{dom_id(person, :email)}") { click_button("email") }
    end

    expect(page).to have_current_path(person_path(person))
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
    expect(page).to have_no_content("SMS temporarily out of service")
    expect(page).to have_no_link("Enable SMS")
  end

  def visit_page
    visit person_path(person)
  end
end
