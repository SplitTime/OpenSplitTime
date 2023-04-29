# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Visit an event group setup page and try various features", type: :system, js: true do
  let(:user) { users(:third_user) }
  let(:owner) { users(:fourth_user) }
  let(:steward) { users(:fifth_user) }
  let(:admin) { users(:admin_user) }

  before do
    organization.update(created_by: owner.id)
    organization.stewards << steward
  end

  let(:organization) { organizations(:dirty_30_running) }
  let(:event_group) { event_groups(:sum) }
  let(:event_1) { event_group.events.first }
  let(:event_2) { event_group.events.second }

  let(:outside_event_group) { event_groups(:rufa_2017) }
  let(:outside_event_1) { outside_event_group.events.first }
  let(:outside_event_2) { outside_event_group.events.second }

  context "The event group is visible" do
    context "The event group has events" do
      scenario "The user is a visitor" do
        visit setup_event_group_path(event_group)

        expect(page).to have_current_path(root_path)
        verify_alert("You need to sign in or sign up before continuing")
      end

      scenario "The user is not the owner and not a steward" do
        login_as user, scope: :user
        visit setup_event_group_path(event_group)

        expect(page).to have_current_path(root_path)
        verify_alert("Access denied")
      end

      scenario "The user owns the organization" do
        login_as owner, scope: :user
        visit setup_event_group_path(event_group)

        verify_public_links_present
        verify_steward_links_present
        verify_admin_links_present
        verify_outside_content_absent
        verify_monitor_mode_returns_to_roster
      end

      scenario "The user is a steward of the organization" do
        login_as steward, scope: :user
        visit setup_event_group_path(event_group)

        verify_public_links_present
        verify_steward_links_present
        verify_admin_links_absent
        verify_outside_content_absent
        verify_monitor_mode_returns_to_roster
      end

      scenario "The user is an admin user" do
        login_as admin, scope: :user
        visit setup_event_group_path(event_group)

        verify_public_links_present
        verify_steward_links_present
        verify_admin_links_present
        verify_outside_content_absent
        verify_monitor_mode_returns_to_roster
      end
    end

    context "The event group has no events" do
      before { event_group.events.each(&:destroy) }

      scenario "The user owns the organization" do
        login_as owner, scope: :user
        visit setup_event_group_path(event_group)

        verify_admin_links_present
        verify_outside_content_absent
        verify_monitor_mode_returns_to_organization
      end

      scenario "The user is a steward of the organization" do
        login_as steward, scope: :user
        visit setup_event_group_path(event_group)

        verify_admin_links_absent
        verify_outside_content_absent
        verify_monitor_mode_returns_to_organization
      end

      scenario "The user is an admin" do
        login_as admin, scope: :user
        visit setup_event_group_path(event_group)

        verify_admin_links_present
        verify_outside_content_absent
        verify_monitor_mode_returns_to_organization
      end
    end
  end

  context "The event group is concealed" do
    before { event_group.update(concealed: true) }

    scenario "The user is a visitor" do
      visit setup_event_group_path(event_group)

      expect(page).to have_current_path(root_path)
      verify_alert("You need to sign in or sign up before continuing")
    end

    scenario "The user is not the owner and not a steward" do
      login_as user, scope: :user

      visit setup_event_group_path(event_group)
      expect(current_path).to eq("/404")
    end

    scenario "The user owns the organization" do
      login_as owner, scope: :user
      visit setup_event_group_path(event_group)

      verify_public_links_present
      verify_steward_links_present
      verify_admin_links_present
      verify_outside_content_absent
    end

    scenario "The user is a steward of the organization" do
      login_as steward, scope: :user
      visit setup_event_group_path(event_group)

      verify_public_links_present
      verify_steward_links_present
      verify_admin_links_absent
      verify_outside_content_absent
    end

    scenario "The user is an admin user" do
      login_as admin, scope: :user
      visit setup_event_group_path(event_group)

      verify_public_links_present
      verify_steward_links_present
      verify_admin_links_present
      verify_outside_content_absent
    end

    # Ensure policy scoping is working as expected, i.e., ignoring created_by
    # and looking only at the organization owner.
    context "The event group has an event that was created by an admin" do
      before { event_2.update(created_by: admin.id) }

      scenario "The user owns the organization" do
        login_as owner, scope: :user
        visit setup_event_group_path(event_group)

        verify_public_links_present
        verify_steward_links_present
        verify_admin_links_present
        verify_outside_content_absent
      end

      scenario "The user is a steward of the organization" do
        login_as steward, scope: :user
        visit setup_event_group_path(event_group)

        verify_public_links_present
        verify_steward_links_present
        verify_admin_links_absent
        verify_outside_content_absent
      end

      scenario "The user is an admin user" do
        login_as admin, scope: :user
        visit setup_event_group_path(event_group)

        verify_public_links_present
        verify_steward_links_present
        verify_admin_links_present
        verify_outside_content_absent
      end
    end
  end

  def verify_public_links_present
    expect(page).to have_content(organization.name)

    expect(page).to have_content(event_1.guaranteed_short_name)
    expect(page).to have_content(event_2.guaranteed_short_name)
  end

  def verify_outside_content_absent
    expect(page).not_to have_content(outside_event_group.name)
    expect(page).not_to have_content(outside_event_1.guaranteed_short_name)
    expect(page).not_to have_content(outside_event_2.guaranteed_short_name)
  end

  def verify_steward_links_present
    expect(page).to have_link(href: edit_event_group_event_path(event_group, event_1), visible: :all)
    expect(page).to have_link(href: edit_event_group_event_path(event_group, event_2), visible: :all)
  end

  def verify_admin_links_absent
    expect(page).not_to have_content("Group Actions")
  end

  def verify_admin_links_present
    expect(page).to have_content("Group Actions")
  end

  def verify_monitor_mode_returns_to_roster
    click_link "Return to monitor mode"
    expect(page).not_to have_content("You are in Construction Mode")
    expect(page).to have_content("Roster")
  end

  def verify_monitor_mode_returns_to_organization
    click_link "Return to monitor mode"
    expect(page).not_to have_content("You are in Construction Mode")
    event_group.organization.event_groups.each { |event_group| expect(page).to have_content(event_group.name) }
  end
end
