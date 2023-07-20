# frozen_string_literal: true

require "rails_helper"

RSpec.describe "visit the webhooks page", js: true do
  let(:user) { users(:third_user) }
  let(:admin) { users(:admin_user) }
  let(:event_group) { event_groups(:hardrock_2015) }
  let(:event) { event_group.events.first }

  scenario "A visitor views the webhooks page" do
    visit_page
    expect(page).to have_current_path(root_path)
    expect(page).to have_content("You need to sign in or sign up before continuing")
  end

  scenario "A user views the webhooks page" do
    login_as user, scope: :user

    visit_page
    expect(page).to have_content(event_group.name)
    expect(page).to have_current_path(webhooks_path)
  end

  scenario "An admin views the webhooks page" do
    login_as admin, scope: :user

    visit_page
    expect(page).to have_content(event_group.name)
    expect(page).to have_current_path(webhooks_path)
  end

  scenario "The event group has no event with a topic resource key" do
    login_as user, scope: :user

    visit_page
    expect(page).not_to have_link(href: new_event_subscription_path(event))
  end

  scenario "The event group has an event with a topic resource key" do
    event.assign_topic_resource
    event.save!
    login_as user, scope: :user

    visit_page
    expect(page).to have_link("Add Subscription", href: new_event_subscription_path(event))
    click_link("Add Subscription")

    expect(page).to have_content("Add a Subscription")
    fill_in("Endpoint", with: "http://www.example.com")
    sleep 0.2

    expect do
      click_button("Create Subscription")
      expect(page).not_to have_content("Add a Subscription")
    end.to change(Subscription, :count).by(1)
  end

  def visit_page
    visit webhooks_path
  end

  def webhooks_path
    webhooks_event_group_path(event_group)
  end
end
