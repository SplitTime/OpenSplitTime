require "rails_helper"

RSpec.describe "visit a lottery setup page" do
  let(:user) { users(:third_user) }
  let(:owner) { users(:fourth_user) }
  let(:steward) { users(:fifth_user) }
  let(:admin) { users(:admin_user) }

  before do
    organization.update(created_by: owner.id)
    organization.stewards << steward
  end

  let(:lottery) { lotteries(:lottery_with_tickets_and_draws) }
  let(:organization) { lottery.organization }

  before { lottery.update(status: :preview) }

  scenario "The user is an admin" do
    login_as admin, scope: :user

    visit_page
    verify_all_content_present
  end

  scenario "The user is the owner of the organization" do
    login_as owner, scope: :user

    visit_page
    verify_all_content_present
  end

  scenario "The user is a lottery manager of the organization" do
    stewardship = Stewardship.find_by(user: steward, organization: organization)
    stewardship.update(level: :lottery_manager)

    login_as steward, scope: :user

    visit_page
    verify_all_content_present
  end

  scenario "The user is a steward who is not a lottery manager of the organization" do
    login_as steward, scope: :user

    visit_page
    expect(page).to have_current_path(root_path)
  end

  scenario "The user is a visitor" do
    visit_page
    expect(page).to have_current_path(root_path)
  end

  def visit_page
    visit setup_organization_lottery_path(organization, lottery)
  end

  def verify_all_content_present
    lottery.divisions.each { |division| verify_content_present(division) }
  end
end
