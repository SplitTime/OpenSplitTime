require "rails_helper"

RSpec.describe "visit the follow page" do
  let(:user) { users(:third_user) }
  let(:admin) { users(:admin_user) }
  let(:event_group) { event_groups(:hardrock_2015) }
  let(:event) { event_group.events.first }

  scenario "A visitor views the follow page" do
    visit_page
    expect(page).to have_content(event_group.name)
    expect(page).to have_content("Sign up for an account or log in to your existing account")
  end

  scenario "A user views the follow page" do
    login_as user, scope: :user

    visit_page
    expect(page).to have_content(event_group.name)
    expect(page).not_to have_content("Sign up for an account or log in to your existing account")
  end

  scenario "An admin views the follow page" do
    login_as admin, scope: :user

    visit_page
    expect(page).to have_content(event_group.name)
    expect(page).not_to have_content("Sign up for an account or log in to your existing account")
  end

  scenario "The event group has no event with a topic resource key" do
    login_as user, scope: :user

    visit_page
    expect(page).not_to have_link(href: webhooks_event_group_path(event_group))
  end

  scenario "The event group has an event with a topic resource key" do
    event.assign_topic_resource
    event.save!
    login_as user, scope: :user

    visit_page
    expect(page).to have_link(href: webhooks_event_group_path(event_group))
  end

  def visit_page
    visit follow_event_group_path(event_group)
  end
end
