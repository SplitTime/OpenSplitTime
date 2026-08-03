require "rails_helper"

RSpec.describe "highlight entrants on the spread page", :js do
  let(:event) { events(:hardrock_2015) }
  let(:effort) { efforts(:hardrock_2015_tuan_jacobs) }
  let(:other_effort) { efforts(:hardrock_2015_erich_larson) }

  scenario "toggle, persist, filter, and clear highlights" do
    visit_with_clean_store

    highlight_button(effort).click
    expect(page).to have_css("tr#effort_#{effort.id}.effort-highlighted")
    expect(page).to have_content("1 highlighted")

    visit spread_event_path(event)
    expect(page).to have_css("tr#effort_#{effort.id}.effort-highlighted")

    click_button "Show only highlighted"
    expect(page).to have_selector("tr#effort_#{effort.id}")
    expect(page).not_to have_selector("tr#effort_#{other_effort.id}")

    click_button "Clear"
    expect(page).not_to have_css("tr.effort-highlighted")
    expect(page).to have_selector("tr#effort_#{other_effort.id}")
    expect(page).not_to have_content("highlighted")
  end

  scenario "a shared link fragment seeds highlights" do
    visit_with_clean_store

    visit "#{spread_event_path(event)}#highlight=#{effort.id}"
    expect(page).to have_css("tr#effort_#{effort.id}.effort-highlighted")
    expect(page).to have_content("1 highlighted")
    expect(page).not_to have_css("tr#effort_#{other_effort.id}.effort-highlighted")
  end

  def highlight_button(effort)
    page.find("tr#effort_#{effort.id} button[aria-label='Highlight this entrant']")
  end

  def visit_with_clean_store
    visit spread_event_path(event)
    page.execute_script("localStorage.clear()")
    visit spread_event_path(event)
  end
end
