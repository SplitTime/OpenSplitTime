# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Visit a legacy course url" do
  let(:course) { courses(:hardrock_cw) }
  let(:organization) { course.organization }

  scenario "Visitor visits a legacy url" do
    visit "courses/#{course.to_param}"

    expect(page).to have_current_path(organization_course_path(organization, course))
  end

  scenario "Visitor visits a legacy url with a tail" do
    visit "courses/#{course.to_param}/best_efforts"

    expect(page).to have_current_path(organization_course_best_efforts_path(organization, course))
  end
end
