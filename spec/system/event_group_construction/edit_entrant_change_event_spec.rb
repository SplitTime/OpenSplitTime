# frozen_string_literal: true

require "rails_helper"

RSpec.describe "change an entrant's event", js: true do
  include ActionView::RecordIdentifier
  include ActiveJob::TestHelper

  let(:steward) { users(:fifth_user) }

  before { organization.stewards << steward }

  let(:event_group) { event_groups(:sum) }
  let(:organization) { event_group.organization }
  let(:entrant) { event_group.efforts.find_by(first_name: "Progress", last_name: "Cascade") }

  context "when the entrant has not yet started" do
    before do
      entrant.split_times.delete_all
      entrant.reload
    end

    scenario "Change an entrant's event" do
      login_as steward, scope: :user
      visit_page

      within("##{dom_id(entrant, :event_group_setup)}") do
        button = page.find("button.dropdown-toggle")
        button.click
        click_link "Edit"
      end

      expect(page).to have_content("Edit Entrant - #{entrant.full_name}")
      select "55K", from: "effort_event_id"
      sleep 0.5
      expect do
        click_button "Update Entrant"
        expect(page).not_to have_css("#form_modal .modal-header")
      end.to change { entrant.reload.event }.from(events(:sum_100k)).to(events(:sum_55k))

      within("##{dom_id(entrant, :event_group_setup)}") do
        expect(page).to have_content(events(:sum_55k).short_name)
      end
    end
  end

  context "when the entrant has started but has no other split times" do
    before do
      entrant.split_times.includes(:split).where.not(split: { kind: :start }).delete_all
      entrant.reload
    end

    scenario "Change an entrant's event" do
      login_as steward, scope: :user
      visit_page

      within("##{dom_id(entrant, :event_group_setup)}") do
        button = page.find("button.dropdown-toggle")
        button.click
        click_link "Edit"
      end

      expect(page).to have_content("Edit Entrant - #{entrant.full_name}")
      select "55K", from: "effort_event_id"
      sleep 0.5
      expect do
        click_button "Update Entrant"
        expect(page).not_to have_css("#form_modal .modal-header")
      end.to change { entrant.reload.event }.from(events(:sum_100k)).to(events(:sum_55k))

      within("##{dom_id(entrant, :event_group_setup)}") do
        expect(page).to have_content(events(:sum_55k).short_name)
      end
    end
  end

  context "when the entrant has split times beyond start that match the split names of the other event" do
    before do
      entrant.split_times.where(split: splits(:sum_100k_course_cascade_creek_rd_aid3)).delete_all
      entrant.reload
    end

    scenario "Change an entrant's event" do
      login_as steward, scope: :user
      visit_page

      within("##{dom_id(entrant, :event_group_setup)}") do
        button = page.find("button.dropdown-toggle")
        button.click
        click_link "Edit"
      end

      expect(page).to have_content("Edit Entrant - #{entrant.full_name}")
      select "55K", from: "effort_event_id"
      sleep 0.5
      expect do
        click_button "Update Entrant"
        expect(page).not_to have_css("#form_modal .modal-header")
      end.to change { entrant.reload.event }.from(events(:sum_100k)).to(events(:sum_55k))

      within("##{dom_id(entrant, :event_group_setup)}") do
        expect(page).to have_content(events(:sum_55k).short_name)
      end
    end
  end

  context "when the entrant has split times that do not match the split names of the other event" do
    scenario "Fail to change an entrant's event" do
      login_as steward, scope: :user
      visit_page

      within("##{dom_id(entrant, :event_group_setup)}") do
        button = page.find("button.dropdown-toggle")
        button.click
        click_link "Edit"
      end

      expect(page).to have_content("Edit Entrant - #{entrant.full_name}")
      select "55K", from: "effort_event_id"
      sleep 0.5
      expect do
        click_button "Update Entrant"
        expect(page).to have_content("split times corresponding to split names that do not coincide")
      end.not_to change { entrant.reload.event }.from(events(:sum_100k))

      expect(page).to have_css("#form_modal .modal-header")
    end
  end

  def visit_page
    visit entrants_event_group_path(event_group)
  end
end
