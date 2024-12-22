# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Visit the course group best efforts page", js: true do
  let(:course_group) { course_groups(:both_directions) }
  let(:course_group_events) { [events(:hardrock_2014), events(:hardrock_2015), events(:hardrock_2016)] }
  let(:organization) { course_group.organization }
  # Expected count is the number of finished efforts + 1 for the header row
  let(:expected_count) { ::Effort.where(event: course_group_events).finished.count + 1 }
  let(:half_of_expected) { expected_count / 2 }

  before { EffortSegment.set_all }
  after { EffortSegment.delete_all }

  scenario "Visitor visits the page" do
    visit organization_course_group_best_efforts_path(course_group.organization, course_group)

    expect(page).to have_content(course_group.name)
    expect(page).to have_selector("tr", count: expected_count)
    expect(page).to have_text("End of List")
  end

  scenario "Visitor visits the page and uses auto pagination" do
    visit_page_with_pagination(half_of_expected)
    scroll_to_bottom_of_page
    expect(page).not_to have_link("Show More")
    expect(page).to have_text("End of List")
  end

  def visit_page_with_pagination(per_page)
    visit organization_course_group_best_efforts_path(course_group.organization, course_group, per_page: per_page)
  end

  def scroll_to_bottom_of_page
    execute_script('window.scrollTo(0, document.body.scrollHeight)')
  end
end
