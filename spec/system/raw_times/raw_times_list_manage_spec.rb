require "rails_helper"

RSpec.describe "manage raw times from the raw times list", js: true do
  include ActionView::RecordIdentifier

  let(:steward) { users(:fifth_user) }

  before { organization.stewards << steward }

  let(:effort) { efforts(:sum_100k_drop_anvil) }
  let(:event_group) { event_groups(:sum) }
  let(:organization) { event_group.organization }
  let(:split) { splits(:sum_100k_course_rolling_pass_aid2) }
  let(:bitkey) { SubSplit::OUT_BITKEY }

  let(:raw_time) { event_group.raw_times.find_by!(bib_number: effort.bib_number, split_name: split.base_name, bitkey: bitkey, entered_time: "09:10:00") }

  scenario "toggle a raw time as having been reviewed and not reviewed" do
    login_as steward, scope: :user
    visit_page

    within(page.find("##{dom_id(raw_time)}")) do
      button = page.find("#set-reviewed-raw-time-#{raw_time.id}")
      expect do
        button.click
        page.find("#set-unreviewed-raw-time-#{raw_time.id}")
      end.to change { raw_time.reload.reviewed_at? }.from(false).to(true)
    end

    within(page.find("##{dom_id(raw_time)}")) do
      button = page.find("#set-unreviewed-raw-time-#{raw_time.id}")
      expect do
        button.click
        page.find("#set-reviewed-raw-time-#{raw_time.id}")
      end.to change { raw_time.reload.reviewed_at? }.from(true).to(false)
    end
  end

  scenario "delete a raw time" do
    login_as steward, scope: :user
    visit_page

    expect do
      button = page.find("#delete-raw-time-#{raw_time.id}")
      button.click
      page.accept_confirm
      expect(page).to have_content("Raw time was deleted")
    end.to change { event_group.reload.raw_times.count }.by(-1)
  end

  def visit_page
    visit raw_times_event_group_path(event_group)
  end
end
