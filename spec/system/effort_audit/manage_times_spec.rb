require "rails_helper"

RSpec.describe "manage times from an effort audit page", js: true do
  include ActionView::RecordIdentifier

  let(:steward) { users(:fifth_user) }

  before do
    organization.stewards << steward
  end

  let(:effort) { efforts(:sum_100k_drop_anvil) }
  let(:event) { effort.event }
  let(:event_group) { event.event_group }
  let(:organization) { event_group.organization }

  let(:audit_row) { EffortAuditRow.new(lap_split: lap_split, bitkey: bitkey) }
  let(:lap_split) { LapSplit.new(1, split) }
  let(:split) { splits(:sum_100k_course_rolling_pass_aid2) }
  let(:bitkey) { SubSplit::OUT_BITKEY }

  let(:raw_time_1) { event_group.raw_times.find_by!(bib_number: effort.bib_number, split_name: split.base_name, bitkey: bitkey, entered_time: "09:10:00") }
  let(:raw_time_2) { event_group.raw_times.find_by!(bib_number: effort.bib_number, split_name: split.base_name, bitkey: bitkey, entered_time: "01:03:04") }
  let(:raw_time_3) { event_group.raw_times.find_by!(bib_number: effort.bib_number, split_name: split.base_name, bitkey: bitkey, entered_time: "01:03:05") }
  let(:split_time) { effort.split_times.find_by!(split: split, bitkey: bitkey) }

  scenario "Prefer one raw time over the currently preferred raw time" do
    login_as steward, scope: :user
    visit_page

    within(page.find("##{dom_id(audit_row)}")) do
      button = page.find("#match-raw-time-#{raw_time_1.id}")
      expect do
        button.click
        expect(page).to have_content("Sat 09:10:00")
      end.to change { split_time.reload.absolute_time_local }
               .from("2017-09-24 01:03:05".in_time_zone("Mountain Time (US & Canada)"))
               .to("2017-09-23 09:10:00".in_time_zone("Mountain Time (US & Canada)"))
    end
  end

  scenario "Unmatch a raw time" do
    login_as steward, scope: :user
    visit_page

    within(page.find("##{dom_id(audit_row)}")) do
      button = page.find("#unmatch-raw-time-#{raw_time_3.id}")
      expect do
        button.click
        page.find("#disassociate-raw-time-#{raw_time_3.id}")
      end.to change { raw_time_3.reload.split_time_id }.from(split_time.id).to(nil)
    end
  end

  scenario "Match a raw time" do
    login_as steward, scope: :user
    visit_page

    within(page.find("##{dom_id(audit_row)}")) do
      button = page.find("#match-raw-time-#{raw_time_2.id}")
      expect do
        button.click
        expect(page).to have_content("Sun 01:03:04")
      end.to change { raw_time_2.reload.split_time_id }.from(nil).to(split_time.id)
    end
  end

  scenario "Create a new split time from a raw time" do
    split_time.destroy!

    login_as steward, scope: :user
    visit_page

    within(page.find("##{dom_id(audit_row)}")) do
      button = page.find("#match-raw-time-#{raw_time_1.id}")
      expect do
        button.click
        expect(page).to have_content("Sat 09:10:00")
      end.to change { effort.split_times.count }.by(1).and change { raw_time_1.reload.split_time_id }.from(nil)
    end
  end

  scenario "Disassociate and re-associate a raw time" do
    login_as steward, scope: :user
    visit_page

    within(page.find("##{dom_id(audit_row)}")) do
      button = page.find("#disassociate-raw-time-#{raw_time_2.id}")
      expect do
        button.click
        page.find("#associate-raw-time-#{raw_time_2.id}")
      end.to change { raw_time_2.reload.disassociated_from_effort }.from(nil).to(true)
    end

    within(page.find("##{dom_id(audit_row)}")) do
      button = page.find("#associate-raw-time-#{raw_time_2.id}")
      expect do
        button.click
        page.find("#disassociate-raw-time-#{raw_time_2.id}")
      end.to change { raw_time_2.reload.disassociated_from_effort }.from(true).to(false)
    end
  end

  def visit_page
    visit audit_effort_path(effort)
  end
end
