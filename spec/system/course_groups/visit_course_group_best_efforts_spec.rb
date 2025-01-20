require "rails_helper"

RSpec.describe "Visit the course group best efforts page", js: true do
  let(:course_group) { course_groups(:both_directions) }
  let(:course_group_events) { [events(:hardrock_2014), events(:hardrock_2015), events(:hardrock_2016)] }
  let(:organization) { course_group.organization }
  # Expected count is the number of finished efforts + 1 for the header row
  let(:expected_count) { ::Effort.where(event: course_group_events).finished.count + 1 }
  let(:half_of_expected) { expected_count / 2 }

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

  scenario "Visitor visits the page" do
    visit_page
    verify_public_content_present
    verify_private_content_absent
  end

  scenario "Visitor visits the page and uses auto pagination" do
    visit_page_with_pagination(half_of_expected)
    scroll_to_bottom_of_page
    expect(page).not_to have_link("Show More")
    expect(page).to have_text("End of List")
  end

  def visit_page
    visit organization_course_group_best_efforts_path(course_group.organization, course_group)
  end

  def visit_page_with_pagination(per_page)
    visit organization_course_group_best_efforts_path(course_group.organization, course_group, per_page: per_page)
  end

  def scroll_to_bottom_of_page
    execute_script('window.scrollTo(0, document.body.scrollHeight)')
  end

  def verify_public_content_present
    expect(page).to have_content(course_group.name)
    expect(page).to have_selector("tr", count: expected_count)
    expect(page).to have_text("End of List")
  end

  def verify_private_content_present
    expect(page).to have_button("Export CSV")
  end

  def verify_private_content_absent
    expect(page).not_to have_button("Export CSV")
  end
end
