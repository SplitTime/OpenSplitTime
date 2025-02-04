require "rails_helper"

RSpec.describe "Visit an organization courses page and try various features" do
  let(:user) { users(:third_user) }
  let(:owner) { users(:fourth_user) }
  let(:steward) { users(:fifth_user) }
  let(:admin) { users(:admin_user) }

  before do
    organization.update(created_by: owner.id)
    organization.stewards << steward
  end

  let(:organization) { organizations(:hardrock) }
  let(:concealed_course) { courses(:hardrock_cw) }
  let(:visible_course) { courses(:hardrock_ccw) }
  let(:course_group) { course_groups(:both_directions) }

  let(:outside_organization) { organizations(:running_up_for_air) }
  let(:outside_course) { courses(:rufa_course) }

  before { concealed_course.update!(concealed: true) }

  scenario "The user is a visitor" do
    visit_page

    verify_public_links_present
    verify_concealed_content_absent
    verify_outside_content_absent
  end

  scenario "The user is not the owner and not a steward" do
    login_as user, scope: :user
    visit_page

    verify_public_links_present
    verify_concealed_content_absent
    verify_outside_content_absent
  end

  scenario "The user owns the organization" do
    login_as owner, scope: :user
    visit_page

    verify_public_links_present
    verify_concealed_links_present
    verify_outside_content_absent
  end

  scenario "The user is a steward of the organization" do
    login_as steward, scope: :user
    visit_page

    verify_public_links_present
    verify_concealed_links_present
    verify_outside_content_absent
  end

  scenario "The user is an admin user" do
    login_as admin, scope: :user
    visit_page

    verify_public_links_present
    verify_concealed_links_present
    verify_outside_content_absent
  end

  def verify_public_links_present
    expect(page).to have_content(organization.name)
    expect(page).to have_content("Courses")
    expect(page).to have_content("Events")

    within("#courses") do
      expect(page).to have_content(visible_course.name)
    end

    within("#course_groups") do
      expect(page).to have_content(course_group.name)
    end
  end

  def verify_outside_content_absent
    within("#courses") do
      expect(page).not_to have_content(outside_course.name)
    end
  end

  def verify_concealed_content_absent
    expect(page).not_to have_content("Stewards")

    within("#courses") do
      expect(page).not_to have_content(concealed_course.name)
    end
  end

  def verify_concealed_links_present
    within("#courses") do
      expect(page).to have_content(concealed_course.name)
    end
  end

  def visit_page
    visit organization_courses_path(organization)
  end
end
