# frozen_string_literal: true

require "rails_helper"

RSpec.describe "visit an effort place page" do
  let(:event) { events(:hardrock_2014) }
  let(:organization) { event.organization }

  let(:completed_effort) { efforts(:hardrock_2014_finished_first) }
  let(:in_progress_effort) { efforts(:hardrock_2014_progress_sherman) }
  let(:unstarted_effort) { efforts(:hardrock_2014_not_started) }
  let(:popover_effort) { efforts(:hardrock_2014_keith_metz) }

  context "When the effort is finished" do
    let(:effort) { completed_effort }

    scenario "Visit the page" do
      visit place_effort_path(effort)
      verify_page_header
      verify_split_names
    end
  end

  context "when the effort is partially finished" do
    let(:effort) { in_progress_effort }

    scenario "Visit the page" do
      visit place_effort_path(effort)
      verify_page_header
      verify_split_names
    end
  end

  context "when the effort is not started" do
    let(:effort) { unstarted_effort }

    scenario "Visit the page" do
      visit place_effort_path(effort)
      verify_page_header
      expect(page).to have_text("The effort has not started")
    end
  end

  context "when an effort has peers" do
    let(:effort) { popover_effort }

    scenario "Click a popover button", js: true do
      split = splits(:hardrock_cw_telluride)

      visit place_effort_path(effort)
      within "#lap_1_split_#{split.id}" do
        first("[data-controller='popover']").click
      end
      expect(page).to have_css(".popover-body")
      within ".popover-body" do
        expect(page).to have_css(".table")
        within ".table" do
          expect(page).to have_content("Paul Predovic")
          expect(page).to have_content("Irvin Corkery")
        end
      end
    end
  end

  def verify_page_header
    expect(page).to have_content(effort.full_name)
    expect(page).to have_link("Split times", href: effort_path(effort))
    expect(page).to have_link("Analyze times", href: analyze_effort_path(effort)) unless effort == unstarted_effort
  end

  def verify_split_names
    event.splits.each { |split| expect(page).to have_content(split.base_name) }
  end
end
