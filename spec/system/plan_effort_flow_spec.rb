# frozen_string_literal: true

require "rails_helper"

RSpec.describe "visit the plan efforts page and plan an effort" do
  let(:user) { users(:third_user) }
  let(:admin) { users(:admin_user) }
  let(:course) { courses(:hardrock_ccw) }
  let(:organization) { organizations(:hardrock) }

  scenario "The user is a visitor" do
    visit_page
    fill_in "hh:mm", with: "38:00"
    click_button "Create my plan"

    verify_page_content
  end

  scenario "The user is a user" do
    login_as user, scope: :user

    visit_page
    fill_in "hh:mm", with: "38:00"
    click_button "Create my plan"

    verify_page_content
  end

  scenario "The user is an admin" do
    login_as admin, scope: :user

    visit_page
    fill_in "hh:mm", with: "38:00"
    click_button "Create my plan"

    verify_page_content
  end

  scenario "The user enters a time outside the normal scope" do
    visit_page
    fill_in "hh:mm", with: "18:00"
    click_button "Create my plan"

    verify_content_present(course)
    expect(page).to have_content("Insufficient data to create a plan.")
  end

  context "when a course has had no events held on it" do
    let!(:course) { create(:course, organization: organization) }

    scenario "The user is a visitor" do
      visit_page

      verify_content_present(course)
      expect(page).to have_content("No events have been held on this course.")
    end
  end

  scenario "Inputmask works", js: true do
    visit_page

    expected_values = {
      "1" => "10:00",
      "12" => "12:00",
      "1212" => "12:12",
      "920" => "92:00",
      "131415" => "13:14",
    }

    input = page.find("#expected_time")

    expected_values.each do |input_value, expected_value|
      input.set("")
      input.native.send_keys(input_value)
      input.native.send_keys(:tab)

      expect(input.value).to eq(expected_value)
    end
  end

  def verify_page_content
    verify_content_present(course)
    course.splits.each { |split| verify_content_present(split, :base_name) }
  end

  def visit_page
    visit plan_effort_organization_course_path(organization, course)
  end
end
