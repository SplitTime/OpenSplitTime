require "rails_helper"

RSpec.describe "manage check-ins from the event group roster page", js: true do
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

  context "bulk check in and out" do
    let(:effort_1) do
      efforts(:rufa_2017_12h_not_started)
    end
    let(:effort_2) do
      efforts(:rufa_2017_24h_not_started)
    end
    let(:all_efforts) do
      [effort_1, effort_2]
    end

    scenario "check in all" do
      all_efforts.each { |effort| effort.update(checked_in: false) }

      login_as steward, scope: :user
      visit_page

      button = page.find("#check_in_all")
      expect do
        button.click
        page.accept_confirm
        wait_for_spinner_to_stop
      end.to change { effort_1.reload.checked_in }.from(false).to(true).and change { effort_2.reload.checked_in }.from(false).to(true)
    end

    scenario "check out all" do
      all_efforts.each { |effort| effort.update(checked_in: true) }

      login_as steward, scope: :user
      visit_page

      button = page.find("#check_out_all")
      expect do
        button.click
        page.accept_confirm
        wait_for_spinner_to_stop
      end.to change { effort_1.reload.checked_in }.from(true).to(false).and change { effort_2.reload.checked_in }.from(true).to(false)
    end
  end

  def visit_page
    visit roster_event_group_path(event_group)
  end
end
