require "rails_helper"

RSpec.describe "draw tickets from the lottery draw_tickets page", js: true do
  include ActionView::RecordIdentifier
  include ActiveJob::TestHelper

  let(:steward) { users(:fifth_user) }

  before do
    organization.stewards << steward
    stewardship = organization.stewardships.find_by(user: steward)
    stewardship.update(level: :lottery_manager)
  end

  let(:lottery) { lotteries(:lottery_with_tickets_and_draws) }
  let(:organization) { lottery.organization }
  let(:division_with_draws) { lottery.divisions.find_by(name: "Elses") }
  let(:division_without_draws) { lottery.divisions.find_by(name: "Veterans") }

  before { lottery.update(status: :live) }

  scenario "The user draws tickets" do
    login_and_visit_page

    perform_enqueued_jobs do
      expect do
        within(page.find("##{dom_id(division_with_draws, :draw_tickets_header)}")) { click_link("Draw a Ticket") }
        within(page.find("##{dom_id(division_with_draws, :lottery_draws)}")) do
          expect(page).to have_selector("div.card", count: 3)
        end
      end.to change { division_with_draws.draws.count }.from(2).to(3)

      expect do
        within(page.find("##{dom_id(division_without_draws, :draw_tickets_header)}")) { click_link("Draw a Ticket") }
        within(page.find("##{dom_id(division_without_draws, :lottery_draws)}")) do
          expect(page).to have_selector("div.card", count: 1)
        end
      end.to change { division_without_draws.draws.count }.from(0).to(1)
    end
  end

  scenario "The user draws a ticket for a pre-selected entrant" do
    entrant = division_without_draws.entrants.find_by(first_name: "Veola", last_name: "Cassin")
    entrant.update(pre_selected: true)

    login_and_visit_page

    perform_enqueued_jobs do
      expect do
        within(page.find("##{dom_id(division_without_draws, :draw_tickets_header)}")) do
          click_button("Toggle Dropdown")
          click_link("Draw Veola Cassin")
        end
        within(page.find("##{dom_id(division_without_draws, :lottery_draws)}")) do
          expect(page).to have_selector("div.card", count: 1)
        end
      end.to change { division_without_draws.draws.count }.from(0).to(1)
    end
  end

  def login_and_visit_page
    login_as steward, scope: :user
    visit_page
  end

  def visit_page
    visit draw_tickets_organization_lottery_path(organization, lottery)
  end
end
