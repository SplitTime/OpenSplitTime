# frozen_string_literal: true

require "rails_helper"

RSpec.describe "start ready efforts from the event groups roster page", js: true do
  include ActionView::RecordIdentifier
  include ActiveJob::TestHelper

  let(:steward) { users(:fifth_user) }

  before do
    organization.stewards << steward
  end

  let(:effort) { efforts(:hardrock_2014_not_started) }
  let(:event_group) { event_groups(:hardrock_2014) }
  let(:organization) { event_group.organization }
  let(:event_group_efforts) { event_group.efforts.roster_subquery }

  context "when no efforts are ready to start" do
    before { expect(event_group_efforts.map(&:ready_to_start)).to all eq(false) }

    scenario "start button is disabled" do
      login_as steward, scope: :user
      visit_page

      within("##{dom_id(event_group, :start_ready_efforts_button)}") do
        expect(page).to have_button("Nothing to start", disabled: true)
      end
    end
  end

  context "when an unstarted effort is ready to start" do
    before { effort.update(checked_in: true) }

    scenario "start the entrant" do
      perform_enqueued_jobs do
        login_as steward, scope: :user
        visit_page

        within("##{dom_id(event_group, :start_ready_efforts_button)}") do
          click_button("Start Entrants")
          click_link("(1) scheduled at Friday, July 11, 2014 06:00 (MDT)")
        end

        sleep 0.5

        expect {
          within("#form_modal") do
            expect(page).to have_button("Start")
            fill_in "Actual start time", with: "07/11/2014 06:02"
            click_button "Start"
          end

          within("##{dom_id(effort, :roster_row)}") do
            expect(page).to have_content("Started")
          end
        }.to change { effort.reload.split_times.count }.from(0).to(1)

        expect(effort.starting_split_time.absolute_time).to eq("2014-07-11 06:02:00".in_time_zone(event_group.home_time_zone))
      end
    end
  end

  context "when an effort in progress without a start time is ready to start" do
    let(:effort) { efforts(:hardrock_2014_without_start) }

    before { effort.update(checked_in: true) }

    scenario "start the entrant" do
      perform_enqueued_jobs do
        login_as steward, scope: :user
        visit_page

        within("##{dom_id(event_group, :start_ready_efforts_button)}") do
          click_button("Start Entrants")
          click_link("(1) scheduled at Friday, July 11, 2014 06:00 (MDT)")
        end

        sleep 0.5

        expect {
          within("#form_modal") do
            expect(page).to have_button("Start")
            fill_in "Actual start time", with: "07/11/2014 06:02"
            click_button "Start"
          end

          within("##{dom_id(effort, :roster_row)}") do
            expect(page).to have_content("Fri 06:02")
          end
        }.to change { effort.reload.split_times.count }.by(1)

        expect(effort.starting_split_time.absolute_time).to eq("2014-07-11 06:02:00".in_time_zone(event_group.home_time_zone))
      end
    end
  end

  def verify_start_button_disabled
    expect(start_button[:disabled]).to eq "disabled"
  end

  def verify_start_button_enabled
    expect(start_button[:disabled]).to be_nil
  end

  def start_button
    page.find_button("Start Entrants")
  end

  def visit_page
    visit roster_event_group_path(event_group)
  end
end
