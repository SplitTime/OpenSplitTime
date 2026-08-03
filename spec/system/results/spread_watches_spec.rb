require "rails_helper"

RSpec.describe "watch entrants on the spread page", :js do
  let(:event) { events(:hardrock_2015) }
  let(:effort) { efforts(:hardrock_2015_tuan_jacobs) }
  let(:other_effort) { efforts(:hardrock_2015_erich_larson) }

  scenario "watched is a first-class selection that clears the gender filter" do
    female_effort = efforts(:hardrock_2015_cassondra_nienow)
    visit_with_clean_store

    click_button "Combined"
    expect(page).not_to have_link("Watched")

    watch_button(effort).click
    watch_button(female_effort).click
    expect(page).to have_css("tr#effort_#{effort.id}.effort-watched")

    visit spread_event_path(event)
    expect(page).to have_css("tr#effort_#{effort.id}.effort-watched")

    click_button "Combined"
    click_link "Female"
    expect(page).not_to have_selector("tr#effort_#{effort.id}")

    click_button "Female"
    click_link "Watched"
    expect(page).to have_selector("tr#effort_#{effort.id}")
    expect(page).to have_selector("tr#effort_#{female_effort.id}")
    expect(page).not_to have_selector("tr#effort_#{other_effort.id}")
    expect(page).to have_button("Watched")

    click_button "Watched"
    expect(page).to have_css("a.dropdown-item.active.disabled", text: "Watched")
    expect(page).not_to have_css("a.dropdown-item.active", text: "Combined")
    click_link "Combined"
    expect(page).to have_selector("tr#effort_#{other_effort.id}")
    expect(page).to have_css("tr#effort_#{effort.id}.effort-watched")
    expect(page).to have_button("Combined")

    find("button[aria-label='Clear all watches']").click
    expect(page).not_to have_css("tr.effort-watched")
    expect(page).not_to have_selector("button[aria-label='Clear all watches']")
  end

  scenario "clearing all watches while in the watched view returns to combined" do
    visit_with_clean_store

    watch_button(effort).click
    click_button "Combined"
    click_link "Watched"
    expect(page).to have_button("Watched")

    find("button[aria-label='Clear all watches']").click
    expect(page).to have_button("Combined")
    expect(page).to have_selector("tr#effort_#{other_effort.id}")
    expect(page).not_to have_css("tr.effort-watched")
  end

  scenario "a shared link fragment seeds watches" do
    visit_with_clean_store

    visit "#{spread_event_path(event)}#watch=#{effort.id}"
    expect(page).to have_css("tr#effort_#{effort.id}.effort-watched")
    expect(page).not_to have_css("tr#effort_#{other_effort.id}.effort-watched")
  end

  scenario "a signed-in user's followed entrants are watched automatically" do
    rufa_event = events(:rufa_2017_12h)
    followed_effort = efforts(:rufa_2017_12h_not_started)
    sign_in users(:admin_user)

    visit spread_event_path(rufa_event)
    page.execute_script("localStorage.clear()")
    visit spread_event_path(rufa_event)

    expect(page).to have_css("tr#effort_#{followed_effort.id}.effort-watched")

    watch_button(efforts(:rufa_2017_12h_progress_lap2)).click
    expect(page).to have_css("tr.effort-watched", count: 2)
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
