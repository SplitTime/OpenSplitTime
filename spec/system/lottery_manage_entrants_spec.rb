# frozen_string_literal: true

require "rails_helper"

RSpec.describe "manage entrants on the lottery setup page", js: true do
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

  before { lottery.update(status: :preview) }

  scenario "The user changes the name of an entrant" do
    login_as steward, scope: :user
    visit_page

    entrant = lottery.entrants.find_by(last_name: "Carter")
    fill_in "filter_search", with: entrant.last_name
    click_on "lottery-entrant-admin-lookup-submit"

    within page.find("##{dom_id(entrant)}") do
      expect(page).to have_content(entrant.full_name)
      expect(page).to have_content(entrant.division.name)
      click_link(href: edit_organization_lottery_lottery_entrant_path(organization, lottery, entrant))

      within page.find("form") do
        fill_in "lottery_entrant_last_name", with: "NewLastName"
        click_button "Update Entrant"
      end

      expect(page).to have_content("NewLastName")
    end

    entrant.reload
    expect(entrant.last_name).to eq("NewLastName")
  end

  scenario "The user attempts to delete an entrant" do
    login_as steward, scope: :user
    visit_page

    entrant = lottery.entrants.find_by(last_name: "Carter")
    fill_in "filter_search", with: entrant.last_name
    click_on "lottery-entrant-admin-lookup-submit"

    within page.find("##{dom_id(entrant)}") do
      expect(page).to have_content(entrant.full_name)
      expect(page).to have_content(entrant.division.name)
      expect {
        click_link(href: organization_lottery_lottery_entrant_path(organization, lottery, entrant))
        page.accept_confirm
      }.not_to change(LotteryEntrant, :count)
    end

    expect(page).to have_content("A lottery entrant cannot be deleted unless all of the entrant's tickets and draws have been deleted first.")

    click_link("Delete tickets")
    fill_in "confirm", with: "DELETE TICKETS"
    expect { click_button "Permanently Delete" }.to change(lottery.draws, :count).to(0).and change(lottery.tickets, :count).to(0)

    fill_in "filter_search", with: entrant.last_name
    click_on "lottery-entrant-admin-lookup-submit"

    expect {
      click_link(href: organization_lottery_lottery_entrant_path(organization, lottery, entrant))
      page.accept_confirm
      expect(page).to have_content("The entrant was deleted.")
    }.to change(LotteryEntrant, :count).by(-1)
  end

  scenario "The user reveals pre-selected entrants" do
    entrant = lottery.entrants.find_by(last_name: "Carter")
    entrant.update(pre_selected: true)

    login_as steward, scope: :user
    visit_page

    expect(page).not_to have_content(entrant.full_name)

    click_button("Reveal")
    expect(page).to have_content(entrant.full_name)
  end

  def visit_page
    visit setup_organization_lottery_path(organization, lottery)
  end
end
