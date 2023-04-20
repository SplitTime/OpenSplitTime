# frozen_string_literal: true

require "rails_helper"

RSpec.describe "visit the edit event group page and make changes", type: :system, js: true do
  let(:user) { users(:third_user) }
  let(:owner) { users(:fourth_user) }
  let(:steward) { users(:fifth_user) }
  let(:admin) { users(:admin_user) }

  before do
    organization.update(created_by: owner.id)
    organization.stewards << steward
  end

  let(:event_group) { event_groups(:sum) }
  let(:organization) { event_group.organization }

  scenario "The user is a visitor" do
    visit_page

    expect(page).to have_current_path(root_path)
    verify_alert("You need to sign in or sign up before continuing")
  end

  scenario "The user is a user that is not authorized to edit the event group" do
    login_as user, scope: :user

    visit_page

    expect(page).to have_current_path(root_path)
    verify_alert("Access denied")
  end

  context "when all entrants have been reconciled" do
    scenario "The user is a steward of the organization" do
      login_as steward, scope: :user

      visit_page
      verify_reconciled_content
    end

    scenario "The user is the owner of the organization" do
      login_as owner, scope: :user

      visit_page
      verify_reconciled_content
    end

    scenario "The user is an admin" do
      login_as admin, scope: :user

      visit_page
      verify_reconciled_content
    end
  end

  context "when some entrants have not been reconciled" do
    before { event_group.efforts.first.update(person: nil) }

    scenario "The user is a steward of the organization" do
      login_as steward, scope: :user

      visit_page
      verify_unreconciled_content
    end

    scenario "The user is the owner of the organization" do
      login_as owner, scope: :user

      visit_page
      verify_unreconciled_content
    end

    scenario "The user is an admin" do
      login_as admin, scope: :user

      visit_page
      verify_unreconciled_content
    end
  end

  def verify_reconciled_content
    expect(page).to have_content("All entrants have been reconciled")
  end

  def verify_unreconciled_content
    expect(page).to have_content(/Showing \d+ of \d+ unreconciled efforts/)
  end

  def visit_page
    visit reconcile_event_group_path(event_group)
  end
end
