require "rails_helper"

RSpec.describe "Visit a course events page" do
  let(:organization) { organizations(:hardrock) }
  let(:course) { courses(:hardrock_cw) }
  let(:events) { course.events }

  let(:user) { users(:third_user) }
  let(:owner) { users(:fourth_user) }
  let(:steward) { users(:fifth_user) }
  let(:admin) { users(:admin_user) }

  before do
    organization.update(created_by: owner.id)
    organization.stewards << steward
  end

  scenario "Visitor visits the page" do
    visit_page
    verify_content_present
  end

  scenario "User visits the page" do
    login_as user, scope: :user

    visit_page
    verify_content_present
  end

  scenario "Steward visits the page" do
    login_as steward, scope: :user

    visit_page
    verify_content_present
  end

  scenario "Owner visits the page" do
    login_as owner, scope: :user

    visit_page
    verify_content_present
  end

  scenario "Admin visits the page" do
    login_as admin, scope: :user

    visit_page
    verify_content_present
  end

  def visit_page
    visit organization_course_path(organization, course)
  end

  def verify_content_present
    expect(page).to have_content(organization.name)
    course.events.each { |event| expect(page).to have_text(event.name) }
  end
end
