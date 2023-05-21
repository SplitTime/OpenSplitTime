# frozen_string_literal: true

require "rails_helper"

RSpec.describe "sync lottery from event group construction", js: true do
  let(:steward) { users(:fifth_user) }

  before { organization.stewards << steward }

  let(:event) { event_group.events.first }
  let(:event_group) { event_groups(:hardrock_2016) }
  let(:organization) { event_group.organization }

  let(:lottery) { lotteries(:lottery_with_tickets_and_draws) }
  before { event.update(lottery: lottery) }


  context "when the event has no entrants" do
    before do
      event.split_times.delete_all
      event.efforts.delete_all
    end

    scenario "Sync lottery" do
      login_as steward, scope: :user
      visit_page

      click_link "Preview sync"

      event.lottery.divisions.flat_map(&:accepted_entrants).each do |entrant|
        expect(page).to have_content(entrant.full_name)
      end

      expect do
        click_button "Sync with lottery"
        accept_confirm
        expect(page).to have_content("Lottery sync was successful")
      end.to change { event.reload.efforts.count }.from(0).to(event.lottery.divisions.flat_map(&:accepted_entrants).count)
    end
  end

  context "when the event has entrants" do
    scenario "Sync lottery" do
      login_as steward, scope: :user
      visit_page

      click_link "Preview sync"

      event.efforts.each do |effort|
        expect(page).to have_content(effort.full_name)
      end

      event.lottery.divisions.flat_map(&:accepted_entrants).each do |entrant|
        expect(page).to have_content(entrant.full_name)
      end

      expect do
        click_button "Sync with lottery"
        accept_confirm
        expect(page).to have_content("Lottery sync was successful")
      end.to change { event.reload.efforts.count }.to(event.lottery.divisions.flat_map(&:accepted_entrants).count)
    end
  end

  def visit_page
    visit link_lotteries_event_group_path(event_group)
  end
end
