require "rails_helper"

RSpec.describe "set data status from the event group roster page", js: true do
  include ActionView::RecordIdentifier
  include ActiveJob::TestHelper

  let(:steward) { users(:fifth_user) }

  before { organization.stewards << steward }

  let(:effort) { efforts(:rufa_2017_12h_finished_first) }
  let(:event_group) { event_groups(:rufa_2017) }
  let(:organization) { event_group.organization }

  scenario "set data status changes effort data status" do
    login_as steward, scope: :user
    visit_page

    button = page.find_button("Set data status")

    expect do
      button.click
      expect(page).to have_content("Updated status")
    end.to change { effort.reload.data_status }.from(nil).to("good")
  end

  scenario "set data status displays the resulting data status" do
    perform_enqueued_jobs do
      login_as steward, scope: :user
      visit_page

      button = page.find_button("Set data status")
      button.click

      within("##{dom_id(effort, :roster_row)}") do
        expect(page).to have_content("good")
      end
    end
  end

  def visit_page
    visit roster_event_group_path(event_group)
  end
end
