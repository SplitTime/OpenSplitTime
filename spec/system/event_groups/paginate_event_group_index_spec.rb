require "rails_helper"

RSpec.describe "Paginate the event_groups index", :js do
  let(:visible_event_group_count) { EventGroup.visible.count }
  let(:per_page) { 3 }

  scenario "Visitor sees Show More link when results exceed per_page" do
    visit event_groups_path(per_page: per_page)

    expect(page).to have_link("Show More")
    expect(event_group_row_count).to eq(per_page)
  end

  scenario "Visitor scrolls to load all pages" do
    visit event_groups_path(per_page: per_page)

    scroll_to_bottom_of_page

    expect(page).to have_text("End of List")
    expect(event_group_row_count).to eq(visible_event_group_count)
  end

  def event_group_row_count
    all("tbody#event_groups_list > tr:not(.sub-row)").count
  end

  def scroll_to_bottom_of_page
    execute_script("window.scrollTo(0, document.body.scrollHeight)")
  end
end
