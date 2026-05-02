require "rails_helper"

RSpec.describe "Raw times list — client-side filtering of live-broadcast rows", :js, type: :system do
  let(:admin) { users(:admin_user) }
  let(:event_group) { event_groups(:sum) }
  let(:matching_split_param) { "anvil-cg-aid6" }
  let(:nonmatching_split_param) { "molas-pass-aid1" }

  before { login_as admin, scope: :user }

  # Mimics what a Turbo Stream broadcast lands in the DOM. We inject a <tr> with
  # the same data attributes the _raw_time partial renders (data-controller and
  # data-raw-time-filter-parameterized-split-name-value), then assert whether
  # the raw_time_filter Stimulus controller kept or removed it.
  def broadcast_row(dom_id:, split_param:)
    page.execute_script(<<~JS)
      const tr = document.createElement("tr");
      tr.id = "#{dom_id}";
      tr.setAttribute("data-controller", "raw-time-filter");
      tr.setAttribute("data-raw-time-filter-parameterized-split-name-value", "#{split_param}");
      tr.innerHTML = "<td colspan='100'>injected</td>";
      document.getElementById("raw_times").prepend(tr);
    JS
  end

  scenario "with no filter, all broadcast rows stay" do
    visit raw_times_event_group_path(event_group)

    broadcast_row(dom_id: "raw_time_99001", split_param: matching_split_param)
    broadcast_row(dom_id: "raw_time_99002", split_param: nonmatching_split_param)

    expect(page).to have_selector("#raw_time_99001")
    expect(page).to have_selector("#raw_time_99002")
  end

  scenario "with split-name filter active, broadcast rows that don't match are removed" do
    visit raw_times_event_group_path(event_group, filter: { parameterized_split_name: matching_split_param })

    broadcast_row(dom_id: "raw_time_99003", split_param: matching_split_param)
    broadcast_row(dom_id: "raw_time_99004", split_param: nonmatching_split_param)

    expect(page).to have_selector("#raw_time_99003")
    expect(page).to have_no_selector("#raw_time_99004")
  end

  scenario "rows with empty split name survive when no filter is active" do
    visit raw_times_event_group_path(event_group)

    broadcast_row(dom_id: "raw_time_99005", split_param: "")

    expect(page).to have_selector("#raw_time_99005")
  end

  scenario "rows with empty split name are removed when a split filter is active" do
    visit raw_times_event_group_path(event_group, filter: { parameterized_split_name: matching_split_param })

    broadcast_row(dom_id: "raw_time_99006", split_param: "")

    expect(page).to have_no_selector("#raw_time_99006")
  end
end
