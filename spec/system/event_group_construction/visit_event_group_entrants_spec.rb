# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Visit an event group entrants page and try various features", type: :system, js: true do
  let(:user) { users(:third_user) }
  let(:owner) { users(:fourth_user) }
  let(:steward) { users(:fifth_user) }
  let(:admin) { users(:admin_user) }

  before do
    organization.update(created_by: owner.id)
    organization.stewards << steward
  end

  let(:organization) { organizations(:hardrock) }
  let(:event_group) { event_groups(:hardrock_2015) }

  context "The event group is visible" do
    context "The event group has entrants" do
      scenario "The user is a visitor" do
        visit_page

        expect(page).to have_current_path(root_path)
        verify_alert("You need to sign in or sign up before continuing")
      end

      scenario "The user is not the owner and not a steward" do
        login_as user, scope: :user
        visit_page

        expect(page).to have_current_path(root_path)
        verify_alert("Access denied")
      end

      scenario "The user owns the organization" do
        login_as owner, scope: :user
        visit_page

        verify_content_present
        verify_actions_links_present
        verify_all_entrants_present
        verify_monitor_mode_returns_to_roster
      end

      scenario "The user is a steward of the organization" do
        login_as steward, scope: :user
        visit_page

        verify_content_present
        verify_actions_links_present
        verify_all_entrants_present
        verify_monitor_mode_returns_to_roster
      end

      scenario "The user is an admin user" do
        login_as admin, scope: :user
        visit_page

        verify_content_present
        verify_actions_links_present
        verify_all_entrants_present
        verify_monitor_mode_returns_to_roster
      end

      scenario "The event group has multiple pages of entrants" do
        login_as owner, scope: :user
        visit_page_with_pagination
        3.times do
          execute_script("window.scrollBy(0, 10000)")
          sleep 0.7
        end

        verify_all_entrants_present
      end
    end

    context "The event group has no entrants" do
      before { event_group.efforts.each(&:destroy) }

      scenario "The user owns the organization" do
        login_as owner, scope: :user
        visit_page

        # Actions menu is not visible when there are no entrants
        verify_actions_links_absent
        verify_content_present
        verify_callout_present
        verify_monitor_mode_returns_to_roster
      end

      scenario "The user is a steward of the organization" do
        login_as steward, scope: :user
        visit_page

        # Actions menu is not visible when there are no entrants
        verify_actions_links_absent
        verify_content_present
        verify_callout_present
        verify_monitor_mode_returns_to_roster
      end

      scenario "The user is an admin" do
        login_as admin, scope: :user
        visit_page

        # Actions menu is not visible when there are no entrants
        verify_actions_links_absent
        verify_content_present
        verify_callout_present
        verify_monitor_mode_returns_to_roster
      end
    end
  end

  context "The event group is concealed" do
    before { event_group.update(concealed: true) }

    scenario "The user is a visitor" do
      visit_page

      expect(page).to have_current_path(root_path)
      verify_alert("You need to sign in or sign up before continuing")
    end

    scenario "The user is not the owner and not a steward" do
      login_as user, scope: :user
      visit_page

      expect(page).to have_current_path("/404")
    end

    scenario "The user owns the organization" do
      login_as owner, scope: :user
      visit_page

      expect(page).to have_current_path(entrants_event_group_path(event_group))
    end

    scenario "The user is a steward of the organization" do
      login_as steward, scope: :user
      visit_page

      expect(page).to have_current_path(entrants_event_group_path(event_group))
    end

    scenario "The user is an admin user" do
      login_as admin, scope: :user
      visit_page

      expect(page).to have_current_path(entrants_event_group_path(event_group))
    end
  end

  def verify_content_present
    expect(page).to have_content(organization.name)

    verify_add_link_present
    verify_import_link_present
  end

  def verify_actions_links_present
    expect(page).to have_button("Actions")
    click_button "Actions"
    expect(page).to have_link("Reconcile")
    expect(page).to have_link("Assign Bibs")
    expect(page).to have_link("Manage Photos")
    expect(page).to have_link("Manage Start Times")
    expect(page).to have_link("Export")
    expect(page).to have_link("Delete all entrants")
  end

  def verify_actions_links_absent
    expect(page).not_to have_button("Actions")
  end

  def verify_add_link_present
    expect(page).to have_link("Add")
  end

  def verify_import_link_present
    expect(page).to have_button("Import")
    click_button "Import"
    expect(page).to have_link("Entrants for the Event Group")
  end

  def verify_all_entrants_present
    event_group.efforts.each do |effort|
      expect(page).to have_content(effort.full_name)
    end
  end

  def verify_callout_present
    expect(page).to have_content("Add or Import Your Entrants")
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

  def visit_page
    visit entrants_event_group_path(event_group)
  end

  def visit_page_with_pagination
    visit entrants_event_group_path(event_group, per_page: 10)
  end
end
