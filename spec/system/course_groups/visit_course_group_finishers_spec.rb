require "rails_helper"

RSpec.describe "Visit the course group finishers page" do
  let(:course_group) { course_groups(:both_directions) }
  let(:course_group_events) { [events(:hardrock_2014), events(:hardrock_2015), events(:hardrock_2016)] }
  let(:organization) { course_group.organization }

  let(:user) { users(:third_user) }
  let(:owner) { users(:fourth_user) }
  let(:steward) { users(:fifth_user) }
  let(:admin) { users(:admin_user) }

  before do
    organization.update(created_by: owner.id)
    organization.stewards << steward
  end

  before(:all) { EffortSegment.set_all }
  after(:all) { EffortSegment.delete_all }

  scenario "Admin visits the page" do
    login_as admin, scope: :user
    visit_page
    verify_public_content_present
    verify_private_content_present
  end

  scenario "Owner visits the page" do
    login_as owner, scope: :user
    visit_page
    verify_public_content_present
    verify_private_content_present
  end

  scenario "Steward visits the page" do
    login_as steward, scope: :user
    visit_page
    verify_public_content_present
    verify_private_content_present
  end

  scenario "User visits the page" do
    login_as user, scope: :user
    visit_page
    verify_public_content_present
    verify_private_content_present
  end

  scenario "Visitor visits the page and searches for a name" do
    visit_page
    verify_public_content_present
    verify_private_content_absent
  end

  def visit_page
    visit organization_course_group_finishers_path(course_group.organization, course_group)
  end

  def verify_public_content_present
    expect(page).to have_content(course_group.name)
  end

  def verify_private_content_present
    expect(page).to have_button("Export CSV")
  end

  def verify_private_content_absent
    expect(page).not_to have_button("Export CSV")
  end
end
