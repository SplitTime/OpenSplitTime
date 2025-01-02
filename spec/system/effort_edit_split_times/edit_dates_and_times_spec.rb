require "rails_helper"

RSpec.describe "edit dates and times from an edit split times page" do
  include ActionView::RecordIdentifier
  let(:steward) { users(:fifth_user) }

  before { organization.stewards << steward }

  let(:effort) { efforts(:sum_55k_progress_rolling) }
  let(:event_group) { effort.event_group }
  let(:organization) { organizations(:dirty_30_running) }

  scenario "Edit an existing split time" do
    login_as steward, scope: :user
    visit_page

    split = splits(:sum_55k_course_molas_pass_aid1)
    split_time = effort.split_times.find_by(split: split, bitkey: SubSplit::OUT_BITKEY)

    expect do
      fill_in "effort_split_times_attributes_2_absolute_time_local", with: "10/07/2017 09:20:00"
      click_button "Update Absolute Times"
      expect(page).to have_current_path(effort_path(effort))
    end.to change { split_time.reload.absolute_time }.from("2017-10-07 15:19:00".in_time_zone).to("2017-10-07 15:20:00".in_time_zone)
  end

  scenario "Create a new split time" do
    login_as steward, scope: :user
    visit_page

    expect do
      fill_in "effort_split_times_attributes_5_absolute_time_local", with: "10/07/2017 13:13:13"
      click_button "Update Absolute Times"
      expect(page).to have_current_path(effort_path(effort))
    end.to change { effort.split_times.count }.from(5).to(6)

    expect(effort.split_times.last.absolute_time_local).to eq("2017-10-07 13:13:13".in_time_zone(event_group.home_time_zone))
  end

  scenario "Delete a split time" do
    login_as steward, scope: :user
    visit_page

    expect do
      fill_in "effort_split_times_attributes_2_absolute_time_local", with: ""
      click_button "Update Absolute Times"
      expect(page).to have_current_path(effort_path(effort))
    end.to change { effort.split_times.count }.from(5).to(4)
  end

  context "with javascript enabled", js: true do
    it "enforces input mask format" do
      login_as steward, scope: :user
      visit_page

      expected_values = {
        "10/07/2017 07:00:00" => "10/07/2017 07:00:00",
        "10/07/2017 07:00" => "10/07/2017 07:00:00",
        "10072017 0700" => "10/07/2017 07:00:00",
        "100720177" => "10/07/2017 07:00:00",
        "10072017" => "10/07/2017 00:00:00",
        "1007" => "10/07/yyyy hh:mm:ss",
      }

      input = page.find("#effort_split_times_attributes_0_absolute_time_local")

      expected_values.each do |input_value, expected_value|
        input.set("")
        input.native.send_keys(input_value)
        input.native.send_keys(:tab)

        expect(input.value).to eq(expected_value)
      end
    end
  end

  def visit_page
    visit edit_split_times_effort_path(effort, display_style: :absolute_time_local)
  end
end
