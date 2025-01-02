require "rails_helper"

RSpec.describe "Visit the cutoff analysis page", js: true do
  let(:course) { courses(:hardrock_ccw) }
  let(:first_split_name) { course.splits.intermediate.first.base_name }

  before(:all) { EffortSegment.set_all }
  after(:all) { EffortSegment.delete_all }

  scenario "Visitor visits the page with existing data" do
    visit_page

    expect(page).to have_content(course.name)
    expect(page).to have_content("Cutoff analysis for #{first_split_name}")
    table = page.find("article").find("table")
    expect(table.all(:css, "tbody tr").size).to eq(5)
  end

  context "when no events exist" do
    before do
      Notification.delete_all
      RawTime.delete_all
      SplitTime.delete_all
      Effort.delete_all
      AidStation.delete_all
      Event.delete_all
    end

    scenario "Visitor visits the page" do
      visit_page

      expect(page).to have_content(course.name)
      expect(page).to have_content("No efforts have been measured at this aid station")
    end
  end

  context "when no events are visible" do
    before { course.events.flat_map(&:event_group).each { |event_group| event_group.update_column(:concealed, true) } }

    scenario "Visitor visits the page" do
      visit_page

      expect(page).to have_content(course.name)
      expect(page).to have_content("No efforts have been measured at this aid station")
    end
  end

  def visit_page
    visit cutoff_analysis_organization_course_path(course.organization, course)
  end
end
