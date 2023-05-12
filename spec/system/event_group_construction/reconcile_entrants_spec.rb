# frozen_string_literal: true

require "rails_helper"

RSpec.describe "reconcile entrants from the reconcile view", js: true do
  let(:steward) { users(:fifth_user) }

  before { organization.stewards << steward }

  let(:event_group) { event_groups(:rufa_2016) }
  let(:organization) { event_group.organization }

  scenario "Auto reconcile" do
    login_as steward, scope: :user
    visit_page

    click_link "Auto Reconcile"
    expect(page).to have_current_path(auto_reconcile_event_group_path(event_group))
    expect(page).to have_content("Automatic reconcile has started")
  end

  def visit_page
    visit reconcile_event_group_path(event_group)
  end
end
