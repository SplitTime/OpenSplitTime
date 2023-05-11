# frozen_string_literal: true

require "rails_helper"

RSpec.describe "manage lottery status on the lottery setup page", js: true do
  include ActionView::RecordIdentifier

  let(:steward) { users(:fifth_user) }

  before do
    organization.stewards << steward
    stewardship = organization.stewardships.find_by(user: steward)
    stewardship.update(level: :lottery_manager)
  end

  let(:lottery) { lotteries(:lottery_with_tickets_and_draws) }
  let(:organization) { lottery.organization }
  let(:division) { lottery.divisions.find_by(name: "Veterans") }

  before { lottery.update(status: :preview) }

  scenario "The user changes the lottery status to Preview" do
    lottery.update(status: :live)
    login_visit_and_click
    expect do
      click_link("Set to Preview")
      expect(page).to have_content("Lottery updated")
    end.to change { lottery.reload.status }.from("live").to("preview")
  end

  scenario "The user changes the lottery status to Live" do
    lottery.update(status: :preview)
    login_visit_and_click
    expect do
      click_link("Set to Live")
      expect(page).to have_content("Lottery updated")
    end.to change { lottery.reload.status }.from("preview").to("live")
  end

  scenario "The user changes the lottery status to Finished" do
    lottery.update(status: :live)
    login_visit_and_click
    expect do
      click_link("Set to Finished")
      expect(page).to have_content("Lottery updated")
    end.to change { lottery.reload.status }.from("live").to("finished")
  end

  scenario "The user changes the lottery visibility to Public" do
    lottery.update(concealed: true)
    login_visit_and_click
    expect do
      click_link("Make public")
      expect(page).to have_content("Lottery updated")
    end.to change { lottery.reload.concealed }.from(true).to(false)
  end

  scenario "The user changes the lottery visibility to Private" do
    lottery.update(concealed: false)
    login_visit_and_click
    expect do
      click_link("Make private")
      expect(page).to have_content("Lottery updated")
    end.to change { lottery.reload.concealed }.from(false).to(true)
  end

  def login_visit_and_click
    login_as steward, scope: :user
    visit_page

    click_button("Lottery")
  end

  def visit_page
    visit setup_organization_lottery_path(organization, lottery)
  end
end
