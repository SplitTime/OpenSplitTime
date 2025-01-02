require "rails_helper"

RSpec.describe "manage tickets and draws on the lottery setup page", js: true do
  include ActionView::RecordIdentifier

  let(:steward) { users(:fifth_user) }

  before do
    organization.stewards << steward
    stewardship = organization.stewardships.find_by(user: steward)
    stewardship.update(level: :lottery_manager)
  end

  let(:lottery) { lotteries(:lottery_with_tickets_and_draws) }
  let(:organization) { lottery.organization }

  before { lottery.update(status: :preview) }

  scenario "The user deletes all draws" do
    login_as steward, scope: :user
    visit_page

    click_link("Delete draws")
    expect(page).to have_field("confirm")
    fill_in "confirm", with: "DELETE DRAWS"
    expect do
      click_button "Permanently Delete"
      expect(page).to have_content("Deleted all lottery draws")
    end.to change { lottery.reload.draws.count }.to(0)
  end

  scenario "The user deletes all tickets" do
    login_as steward, scope: :user
    visit_page

    click_link("Delete tickets")
    expect(page).to have_field("confirm")
    fill_in "confirm", with: "DELETE TICKETS"
    expect do
      click_button "Permanently Delete"
      expect(page).to have_content("Deleted all lottery tickets")
    end.to change { lottery.reload.tickets.count }.to(0).and change { lottery.reload.draws.count }.to(0)
  end

  scenario "The user generates tickets" do
    lottery.draws.delete_all
    lottery.tickets.delete_all
    login_as steward, scope: :user
    visit_page
    expect do
      click_link("Generate tickets")
      expect(page).to have_content("Generated lottery tickets")
    end.to change { lottery.reload.tickets.count }.from(0)
  end

  def visit_page
    visit setup_organization_lottery_path(organization, lottery)
  end
end
