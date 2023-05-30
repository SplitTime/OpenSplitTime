# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Visit the course group finishers page" do
  let(:course_group) { course_groups(:both_directions) }
  let(:course_group_events) { [events(:hardrock_2014), events(:hardrock_2015), events(:hardrock_2016)] }
  let(:organization) { event_group.organization }

  before(:all) { EffortSegment.set_all }
  after(:all) { EffortSegment.delete_all }

  scenario "Visitor visits the page and searches for a name" do
    visit_page

    expect(page).to have_content(course_group.name)
  end

  def visit_page
    visit organization_course_group_finishers_path(course_group.organization, course_group)
  end
end
