# frozen_string_literal: true

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

  let(:raw_time) { event_group.raw_times.find_by!(bib_number: effort.bib_number, split_name: split.base_name, bitkey: bitkey, entered_time: "09:10:00") }

  scenario "Prefer one raw time over the currently preferred raw time" do
    login_as steward, scope: :user
    visit_page

    within(page.find("##{dom_id(audit_row)}")) do
      button = page.find("#match-raw-time-#{raw_time.id}")
      button.click
    end
  end

  def visit_page
    visit audit_effort_path(effort)
  end
end
