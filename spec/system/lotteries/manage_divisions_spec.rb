require "rails_helper"

RSpec.describe "manage divisions on the lottery setup page", js: true do
  include ActionView::RecordIdentifier

  let(:owner) { users(:fourth_user) }
  let(:steward) { users(:fifth_user) }

  before do
    organization.update(created_by: owner.id)
    organization.stewards << steward
    stewardship = organization.stewardships.find_by(user: steward)
    stewardship.update(level: :lottery_manager)
  end

  let(:lottery) { lotteries(:lottery_with_tickets_and_draws) }
  let(:organization) { lottery.organization }
  let(:division) { lottery.divisions.find_by(name: "Veterans") }

  before { lottery.update(status: :preview) }

  scenario "The user changes the name of a division" do
    login_as steward, scope: :user
    visit_page

    within page.find("##{dom_id(division)}") do
      expect(page).to have_content(division.name)
      click_link(href: edit_organization_lottery_lottery_division_path(organization, lottery, division))
    end

    within page.find("form") do
      fill_in "lottery_division_name", with: "New Division Name"
      expect do
        click_button "Update Division"
        expect(page).to have_current_path(setup_organization_lottery_path(organization, lottery))
      end.to change { division.reload.name }.from("Veterans").to("New Division Name")
    end

    within page.find("#lottery_divisions") do
      expect(page).to have_content("New Division Name")
    end
  end

  scenario "The user attempts to delete a division when tickets and draws exist" do
    login_as steward, scope: :user
    visit_page

    expect {
      click_link(href: organization_lottery_lottery_division_path(organization, lottery, division))
      page.accept_confirm
      expect(page).to have_content("A lottery division cannot be deleted unless all tickets and draws have been deleted first.")
    }.not_to change(LotteryDivision, :count)

    expect(page).to have_content(division.name)
  end

  scenario "The user deletes a division when no tickets or draws exist" do
    lottery.delete_all_draws!
    lottery.tickets.delete_all

    login_as steward, scope: :user
    visit_page

    expect {
      click_link(href: organization_lottery_lottery_division_path(organization, lottery, division))
      page.accept_confirm
      expect(page).to have_content("The division was deleted.")
    }.to change(LotteryDivision, :count).by(-1)

    expect(page).not_to have_content(division.name)
  end

  def visit_page
    visit setup_organization_lottery_path(organization, lottery)
  end
end
