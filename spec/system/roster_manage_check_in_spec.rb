# frozen_string_literal: true

require "rails_helper"

RSpec.describe "visit an event group roster page and try various features", js: true do
  include ActionView::RecordIdentifier

  let(:steward) { users(:fifth_user) }

  before { organization.stewards << steward }

  let(:event_group) { event_groups(:rufa_2017) }
  let(:organization) { event_group.organization }

  context "when the entrant is not started" do
    let(:effort) { efforts(:rufa_2017_12h_not_started) }

    scenario "Check in and un-check-in an entrant" do
      login_as steward, scope: :user
      visit_page

      button = page.find("#check-in-effort-#{effort.id}")
      expect do
        button.click
        page.find("#un-check-in-effort-#{effort.id}")
      end.to change { effort.reload.checked_in? }.from(false).to(true)

      button = page.find("#un-check-in-effort-#{effort.id}")
      expect do
        button.click
        page.find("#check-in-effort-#{effort.id}")
      end.to change { effort.reload.checked_in? }.from(true).to(false)
    end
  end

  context "when the entrant is started" do
    let(:effort) { efforts(:rufa_2017_12h_start_only) }

    scenario "Un-start an entrant" do
      login_as steward, scope: :user
      visit_page

      button = page.find("#unstart-effort-#{effort.id}")
      expect do
        button.click
        page.find("#check-in-effort-#{effort.id}")
      end.to change { effort.reload.started? }.from(true).to(false)
    end
  end

  def visit_page
    visit roster_event_group_path(event_group)
  end
end
