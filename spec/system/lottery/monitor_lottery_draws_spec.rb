# frozen_string_literal: true

require "rails_helper"

RSpec.describe "monitor lottery draws", js: true do
  include ActiveJob::TestHelper

  let(:lottery) { lotteries(:lottery_with_tickets_and_draws) }
  let(:division) { lottery.divisions.find_by(name: "Veterans") }
  let(:organization) { lottery.organization }
  let(:entrant) { division.entrants.not_drawn.first }

  before do
    lottery.update(status: :live)
    entrant.update(pre_selected: true)
  end

  scenario "The user watches a random draw" do
    visit_page

    perform_enqueued_jobs do
      within("#lottery_draws") do
        expect(page).to have_selector("div.card", count: 7)
        sleep 1
        division.draw_ticket!
        expect(page).to have_selector("div.card", count: 8)
      end
    end
  end

  scenario "The user watches a pre-selected draw" do
    visit_page

    perform_enqueued_jobs do
      within("#lottery_draws") do
        expect(page).to have_selector("div.card", count: 7)
        sleep 1
        entrant.draw_ticket!
        expect(page).to have_selector("div.card", count: 8)
      end
    end
  end

  def visit_page
    visit organization_lottery_path(organization, lottery, display_style: :draws)
  end
end
