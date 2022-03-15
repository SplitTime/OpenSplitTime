# frozen_string_literal: true

require "rails_helper"

RSpec.describe "visit the podium page" do
  let(:user) { users(:third_user) }
  let(:admin) { users(:admin_user) }
  let(:event) { events(:rufa_2017_24h) }
  let(:subject_efforts) { event.efforts.ranking_subquery }

  scenario "A visitor views the podium page" do
    visit podium_event_path(event)
    verify_podium_view
  end

  scenario "A user views the podium page" do
    login_as user, scope: :user

    visit podium_event_path(event)
    verify_podium_view
  end

  scenario "An admin views the podium page" do
    login_as admin, scope: :user

    visit podium_event_path(event)
    verify_podium_view
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
end
