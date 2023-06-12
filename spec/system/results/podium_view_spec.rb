# frozen_string_literal: true

require "rails_helper"

RSpec.describe "visit the podium page" do
  let(:user) { users(:third_user) }
  let(:admin) { users(:admin_user) }
  let(:event) { events(:rufa_2017_24h) }
  let(:subject_efforts) { event.efforts.ranking_subquery }

  scenario "A visitor views the podium page" do
    visit_page
    verify_podium_view
  end

  scenario "A user views the podium page" do
    login_as user, scope: :user

    visit_page
    verify_podium_view
  end

  scenario "An admin views the podium page" do
    login_as admin, scope: :user

    visit_page
    verify_podium_view
  end

  scenario "Page displays correctly when an effort has no start time" do
    effort = efforts(:rufa_2017_24h_progress_lap1)
    effort.starting_split_time.destroy!

    visit_page
    expect(page).to have_content(effort.full_name)
    verify_podium_view
  end

  scenario "Best Performance works" do
    visit_page
    tables = page.all("table")
    within(tables[0]) { expect(page).to have_content "Overall Men" }

    click_link "Best Performance"

    tables = page.all("table")
    within(tables[0]) { expect(page).to have_content "Overall Women" }
  end

  def verify_podium_view
    expect(page).to have_content(event.name)
    podium_table = page.find("table")

    overall_male_1_row = podium_table.find_by_id("overall_men_1")
    expect(overall_male_1_row).to have_content("Progress Lap6")

    overall_male_2_row = podium_table.find_by_id("overall_men_2")
    expect(overall_male_2_row).to have_content("Finished Last")

    overall_male_3_row = podium_table.find_by_id("overall_men_3")
    expect(overall_male_3_row).to have_content("Progress Lap1")

    overall_women_1_row = podium_table.find_by_id("overall_women_1")
    expect(overall_women_1_row).to have_content("Finished First")

    overall_women_2_row = podium_table.find_by_id("overall_women_2")
    expect(overall_women_2_row).to have_content("Multiple Stops")
  end

  def visit_page
    visit podium_event_path(event)
  end
end
