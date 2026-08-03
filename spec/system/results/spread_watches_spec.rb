require "rails_helper"

RSpec.describe "watch entrants on the spread page", :js do
  let(:event) { events(:hardrock_2015) }
  let(:effort) { efforts(:hardrock_2015_tuan_jacobs) }
  let(:other_effort) { efforts(:hardrock_2015_erich_larson) }

  scenario "toggle, persist, filter, and clear watches" do
    visit_with_clean_store

    click_button "Combined"
    expect(page).not_to have_link("Watched")

    watch_button(effort).click
    expect(page).to have_css("tr#effort_#{effort.id}.effort-watched")

    visit spread_event_path(event)
    expect(page).to have_css("tr#effort_#{effort.id}.effort-watched")

    click_button "Combined"
    click_link "Watched"
    expect(page).to have_selector("tr#effort_#{effort.id}")
    expect(page).not_to have_selector("tr#effort_#{other_effort.id}")
    expect(page).to have_button("Watched")

    click_button "Watched"
    click_link "Combined"
    expect(page).to have_selector("tr#effort_#{other_effort.id}")
    expect(page).to have_css("tr#effort_#{effort.id}.effort-watched")
    expect(page).to have_button("Combined")

    find("button[aria-label='Clear all watches']").click
    expect(page).not_to have_css("tr.effort-watched")
    expect(page).not_to have_selector("button[aria-label='Clear all watches']")
  end

  scenario "a shared link fragment seeds watches" do
    visit_with_clean_store

    visit "#{spread_event_path(event)}#watch=#{effort.id}"
    expect(page).to have_css("tr#effort_#{effort.id}.effort-watched")
    expect(page).not_to have_css("tr#effort_#{other_effort.id}.effort-watched")
  end

  def watch_button(effort)
    page.find("tr#effort_#{effort.id} button[aria-label='Watch this entrant']")
  end

  def visit_with_clean_store
    visit spread_event_path(event)
    page.execute_script("localStorage.clear()")
    visit spread_event_path(event)
  end
end
