# frozen_string_literal: true

require "rails_helper"

RSpec.describe "withdraw entrants from the lottery withdraw_entrants page", js: true do
  include ActionView::RecordIdentifier

  let(:steward) { users(:fifth_user) }

  before do
    organization.stewards << steward
    stewardship = organization.stewardships.find_by(user: steward)
    stewardship.update(level: :lottery_manager)
  end

  let(:lottery) { lotteries(:lottery_with_tickets_and_draws) }
  let(:organization) { lottery.organization }
  let(:entrant) { lottery.entrants.find_by(first_name: "Denisha", last_name: "Carter") }

  scenario "The user withdraws an entrant" do
    login_and_visit_page

    expect do
      within(page.find("##{dom_id(entrant, :withdraw_form)}")) do
        find("##{dom_id(entrant, :withdraw_entrant_checkbox)}").set(true)
      end
      sleep 0.5
    end.to change { entrant.reload.withdrawn? }.from(false).to(true)
  end

  scenario "The user un-withdraws an entrant" do
    entrant.update(withdrawn: true)

    login_and_visit_page

    expect do
      within(page.find("##{dom_id(entrant, :withdraw_form)}")) do
        find("##{dom_id(entrant, :withdraw_entrant_checkbox)}").set(false)
      end
      sleep 0.5
    end.to change { entrant.reload.withdrawn? }.from(true).to(false)
  end

  scenario "The user adds a service form to an entrant" do
    login_and_visit_page

    expect do
      input = page.find("##{dom_id(entrant, :service_completed_date_input)}")
      input.set("05/15/2023")
      input.native.send_keys(:tab)
      within(page.find("##{dom_id(entrant, :service_completed_indicator)}")) do
        expect(page).to have_css("i.fa-circle-check")
      end
    end.to change { entrant.reload.service_completed_date }.from(nil).to("2023-05-15".to_date)
  end

  scenario "The user removes a service form from an entrant" do
    entrant.update(service_completed_date: "2023-05-15".to_date)

    login_and_visit_page

    expect do
      input = page.find("##{dom_id(entrant, :service_completed_date_input)}")
      input.set("")
      input.native.send_keys(:tab)
      within(page.find("##{dom_id(entrant, :service_completed_indicator)}")) do
        expect(page).to have_css("i.fa-circle-xmark")
      end
    end.to change { entrant.reload.service_completed_date }.from("2023-05-15".to_date).to(nil)
  end

  def login_and_visit_page
    login_as steward, scope: :user
    visit_page
  end

  def visit_page
    visit withdraw_entrants_organization_lottery_path(organization, lottery)
  end
end
