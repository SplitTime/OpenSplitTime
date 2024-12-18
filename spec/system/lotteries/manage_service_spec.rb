# frozen_string_literal: true

require "rails_helper"

RSpec.describe "manage lottery service", js: true do
  let(:admin) { users(:admin_user) }
  let(:steward) { users(:fifth_user) }
  let(:user) { users(:fourth_user) }

  before do
    organization.stewards << steward
  end

  let(:lottery) { lotteries(:lottery_with_tickets_and_draws) }
  let(:organization) { lottery.organization }
  let(:entrant) { lottery_entrants(:lottery_entrant_0004) }
  let(:person) { people(:bruno_fadel) }

  before { lottery.update(status: :finished) }

  scenario "user who is an admin" do
    login_as admin, scope: :user
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
