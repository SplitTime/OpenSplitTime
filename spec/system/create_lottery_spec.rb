# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Create and update a lottery" do
  let(:owner) { users(:fourth_user) }
  let(:steward) { users(:fifth_user) }
  let(:admin) { users(:admin_user) }

  before do
    organization.update(created_by: owner.id)
    organization.stewards << steward
  end

  let(:organization) { organizations(:dirty_30_running) }
  let(:new_lottery_name) { "Test Lottery" }
  let(:new_lottery_date) { "12/5/2021" }
  let(:updated_lottery_name) { "Updated Test Lottery" }
  let(:updated_lottery_date) { "1/1/2022" }

  scenario "The user is a visitor" do
    verify_unable_to_create_lottery
  end

  scenario "The user is a steward" do
    login_as steward, scope: :user
    verify_unable_to_create_lottery
  end

  scenario "The user owns the organization" do
    login_as owner, scope: :user
    create_and_verify_lottery
  end

  scenario "The user is an admin" do
    login_as admin, scope: :user
    create_and_verify_lottery
  end

  private

  def verify_unable_to_create_lottery
    visit organization_lotteries_path(organization)
    expect(page).not_to have_link "add-lottery"
  end

  def create_and_verify_lottery
    visit organization_lotteries_path(organization)
    expect(page).to have_link "add-lottery"
    click_link "add-lottery"

    expect(page).to have_content("New Lottery")
    expect(page).to have_button("Create Lottery")

    click_button "Create Lottery"
    expect(page).to have_content(:all, "errors prohibited this record from being saved")

    fill_in "Name", with: new_lottery_name
    fill_in "Scheduled start date", with: new_lottery_date

    expect { click_button "Create Lottery" }.to change { Lottery.count }.by(1)
    new_lottery = Lottery.last
    expect(new_lottery.name).to eq(new_lottery_name)
    expect(new_lottery.scheduled_start_date).to eq(new_lottery_date.to_date)

    verify_link_present([organization, new_lottery])
    click_link new_lottery.name
    click_link "Edit"

    expect(page).to have_content("Edit Lottery")
    expect(page).to have_button("Update Lottery")

    fill_in "Name", with: updated_lottery_name
    fill_in "Scheduled start date", with: updated_lottery_date

    expect { click_button "Update Lottery" }.not_to change { Lottery.count }
    updated_lottery = Lottery.last
    expect(updated_lottery.name).to eq(updated_lottery_name)
    expect(updated_lottery.scheduled_start_date).to eq(updated_lottery_date.to_date)
  end
end
