require "rails_helper"

RSpec.describe "rebuild times from an effort audit page", js: true do
  let(:steward) { users(:fifth_user) }

  before do
    organization.stewards << steward
  end

  let(:effort) { efforts(:rufa_2016_progress_lap1) }
  let(:event) { effort.event }
  let(:event_group) { event.event_group }
  let(:organization) { event_group.organization }

  scenario "No raw times exist for the effort" do
    login_as steward, scope: :user
    visit_page

    expect(page).not_to have_link("Rebuild times")
  end

  scenario "Raw times exist for the effort" do
    event_group.raw_times.create!(
      bib_number: effort.bib_number,
      split_name: "Grandeur Peak",
      bitkey: SubSplit::IN_BITKEY,
      absolute_time: effort.scheduled_start_time_local + 1.hour,
      entered_time: effort.scheduled_start_time_local + 1.hour,
      source: "ost-test",
      )

    event_group.raw_times.create!(
      bib_number: effort.bib_number,
      split_name: "Finish",
      bitkey: SubSplit::IN_BITKEY,
      absolute_time: effort.scheduled_start_time_local + 2.hours,
      entered_time: effort.scheduled_start_time_local + 2.hours,
      source: "ost-test",
    )

    login_as steward, scope: :user
    visit_page

    expect(page).not_to have_content("Sat 07:00:00")
    expect(page).not_to have_content("Sat 08:00:00")

    expect(page).to have_link("Rebuild Times")

    page.accept_confirm do
      click_link("Rebuild Times")
    end

    expect(page).to have_current_path(audit_effort_path(effort))
    expect(page).to have_content("Rebuild completed.")
    expect(page).to have_content("Sat 07:00:00")
    expect(page).to have_content("Sat 08:00:00")
  end

  def visit_page
    visit audit_effort_path(effort)
  end
end
