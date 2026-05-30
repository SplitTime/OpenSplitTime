require "rails_helper"

RSpec.describe "visit the manage service view", :js do
  let(:admin) { users(:admin_user) }
  let(:lottery) { lotteries(:lottery_with_tickets_and_draws) }
  let(:organization) { lottery.organization }
  let(:entrant) { LotteryEntrant.find_by!(first_name: "Jospeh", last_name: "Barrows") }
  let(:person) { people(:bruno_fadel) }
  let(:owner) { users(:third_user) }
  let(:steward) { users(:fifth_user) }
  let(:user) { users(:fourth_user) }

  before do
    organization.update(created_by: owner.id)
    organization.stewards << steward
    lottery.update(status: :finished)
  end

  scenario "user who is an admin" do
    login_as admin, scope: :user
    visit_page

    expect(page).to have_current_path(organization_lottery_entrant_service_detail_path(organization, lottery, entrant))
  end

  scenario "user who is an owner" do
    login_as owner, scope: :user
    visit_page

    expect(page).to have_current_path(organization_lottery_entrant_service_detail_path(organization, lottery, entrant))
  end

  scenario "user who is a steward" do
    login_as steward, scope: :user
    visit_page

    expect(page).to have_current_path(organization_lottery_entrant_service_detail_path(organization, lottery, entrant))
  end

  scenario "user who has the same email as the entrant" do
    entrant.update!(email: user.email)
    login_as user, scope: :user
    visit_page

    expect(page).to have_current_path(organization_lottery_entrant_service_detail_path(organization, lottery, entrant))
  end

  scenario "user who has the same person" do
    entrant.update!(person: person)
    person.update!(claimant: user)
    login_as user, scope: :user
    visit_page

    expect(page).to have_current_path(organization_lottery_entrant_service_detail_path(organization, lottery, entrant))
  end

  scenario "user who is not associated" do
    login_as user, scope: :user
    visit_page

    expect(page).to have_current_path(root_path)
    expect(page).to have_text("Access denied")
  end

  def visit_page
    visit organization_lottery_entrant_service_detail_path(organization, lottery, entrant)
  end
end
