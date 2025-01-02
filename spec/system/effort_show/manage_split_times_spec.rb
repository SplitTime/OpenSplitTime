require "rails_helper"

RSpec.describe "manage split times from an effort show page", js: true do
  include ActionView::RecordIdentifier
  let(:steward) { users(:fifth_user) }

  before do
    organization.stewards << steward
  end

  let(:effort) { efforts(:hardrock_2015_raphael_swift) }
  let(:event) { effort.event }
  let(:event_group) { event.event_group }
  let(:organization) { event_group.organization }
  let(:split) { splits(:hardrock_ccw_ouray) }
  let(:split_time) { effort.split_times.find_by(split: split, bitkey: SubSplit::IN_BITKEY) }


  scenario "Confirm a questionable split time" do
    login_as steward, scope: :user
    visit_page

    cell = page.find("##{dom_id(split, :confirm)}")

    expect do
      within(cell) do
        form = page.first("form")
        within(form) do
          button = page.first("button")
          button.click
        end
      end
      wait_for_spinner_to_stop
    end.to change { split_time.reload.data_status }.from("questionable").to("confirmed")
  end

  scenario "Unconfirm a questionable split time" do
    split_time.update(data_status: "confirmed")

    login_as steward, scope: :user
    visit_page

    cell = page.find("##{dom_id(split, :confirm)}")

    expect do
      within(cell) do
        form = page.first("form")
        within(form) do
          button = page.first("button")
          button.click
        end
      end
      wait_for_spinner_to_stop
    end.to change { split_time.reload.data_status }.from("confirmed").to("questionable")
  end

  scenario "Delete a split time" do
    login_as steward, scope: :user
    visit_page

    cell = page.find("##{dom_id(split, :delete)}")

    expect do
      within(cell) do
        form = page.first("form")
        within(form) do
          button = page.first("button")
          button.click
        end
      end
      page.accept_confirm
      wait_for_spinner_to_stop
    end.to change { effort.reload.split_times.count }.by(-1)
  end

  def visit_page
    visit effort_path(effort)
  end
end
