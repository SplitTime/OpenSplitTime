require "rails_helper"

RSpec.describe "manage check-ins from the event group roster page", :js do
  include ActionView::RecordIdentifier

  let(:steward) { users(:fifth_user) }
  let(:event_group) { event_groups(:rufa_2017) }
  let(:organization) { event_group.organization }

  before { organization.stewards << steward }

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

  context "when checking in or out in bulk" do
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
        page.accept_confirm do
          button.click
        end
        wait_for_spinner_to_stop
      end.to change { effort_1.reload.checked_in }.from(false).to(true).and change { effort_2.reload.checked_in }.from(false).to(true)
    end

    scenario "check out all" do
      started_effort = efforts(:rufa_2017_12h_start_only)
      [*all_efforts, started_effort].each { |effort| effort.update(checked_in: true) }

      login_as steward, scope: :user
      visit_page

      button = page.find("#check_out_all")
      page.accept_confirm { button.click }
      wait_for_spinner_to_stop

      expect(all_efforts.map { |effort| effort.reload.checked_in }).to all(be(false))
      expect(started_effort.reload.checked_in).to be(true)
    end
  end

  def visit_page
    visit roster_event_group_path(event_group)
  end
end
