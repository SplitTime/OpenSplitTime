# frozen_string_literal: true

require "rails_helper"

RSpec.describe "visit a lottery stats page" do
  let(:lottery) { lotteries(:lottery_with_tickets_and_draws) }
  let(:organization) { lottery.organization }

  scenario "User visits the stats view" do
    visit_page
    expect(page).to have_content("Lottery Stats")
  end

  def visit_page
    visit organization_lottery_path(organization, lottery, display_style: :stats)
  end
end
