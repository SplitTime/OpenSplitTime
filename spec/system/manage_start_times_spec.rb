# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Manage start times", type: :system do
  let(:page_path) { manage_start_times_event_group_path(event_group) }

  let(:owner) { users(:fourth_user) }
  let(:steward) { users(:fifth_user) }
  let(:admin) { users(:admin_user) }

  before do
    organization.update(created_by: owner.id)
    organization.stewards << steward
  end

  let(:organization) { organizations(:running_up_for_air) }
  let(:event_group) { event_groups(:rufa_2017) }
  let(:event) { events(:rufa_2017_12h) }

  scenario "The user is a visitor" do
    verify_unable_to_visit_page
  end

  scenario "The user is a steward" do
    login_as steward, scope: :user
    verify_manage_start_times_started
    verify_manage_start_times_unstarted
  end

  scenario "The user owns the organization" do
    login_as owner, scope: :user
    verify_manage_start_times_started
    verify_manage_start_times_unstarted
  end

  scenario "The user is an admin" do
    login_as admin, scope: :user
    verify_manage_start_times_started
    verify_manage_start_times_unstarted
  end

  private

  def verify_unable_to_visit_page
    visit page_path
    expect(page).to have_current_path(root_path)
  end

  def verify_manage_start_times_started
    actual_start_time = "2017-02-11 07:00:00".in_time_zone(event_group.home_time_zone)
    updated_actual_start_time_text = "02/11/2017 07:01:23"

    visit page_path
    expect(page).to have_text "Manage Start Times"
    turbo_frame = find("turbo-frame", id: "#{event.id}_#{actual_start_time.to_i}")
    edit_button = turbo_frame.find("a")

    # Test the cancel button
    edit_button.click
    fill_in "actual_start_time", with: updated_actual_start_time_text
    cancel_button = turbo_frame.find_link(href: page_path)

    expect { cancel_button.click }.not_to change { SplitTime.count }
    efforts = event.efforts.roster_subquery.where(actual_start_time: actual_start_time)
    efforts.each { |effort| expect(effort.actual_start_time).to eq(actual_start_time) }

    # Test the submit button
    edit_button.click
    fill_in "actual_start_time", with: updated_actual_start_time_text
    submit_button = turbo_frame.find('button[type="submit"]')

    expect { submit_button.click }.not_to change { SplitTime.count }
    efforts = event.efforts.roster_subquery.where(actual_start_time: actual_start_time)
    efforts.each { |effort| expect(effort.actual_start_time).to eq(updated_actual_start_time_text.in_time_zone(event_group.home_time_zone)) }
  end

  def verify_manage_start_times_unstarted
    actual_start_time = nil
    updated_actual_start_time_text = "02/11/2017 07:01:23"

    visit page_path
    expect(page).to have_text "Manage Start Times"
    turbo_frame = find("turbo-frame", id: "#{event.id}_#{actual_start_time.to_i}")
    edit_button = turbo_frame.find("a")

    # Test the cancel button
    edit_button.click
    fill_in "actual_start_time", with: updated_actual_start_time_text
    cancel_button = turbo_frame.find_link(href: page_path)

    expect { cancel_button.click }.not_to change { SplitTime.count }
    efforts = event.efforts.roster_subquery.where(actual_start_time: actual_start_time)
    efforts.each { |effort| expect(effort.actual_start_time).to eq(actual_start_time) }

    # Test the submit button
    edit_button.click
    fill_in "actual_start_time", with: updated_actual_start_time_text
    submit_button = turbo_frame.find('button[type="submit"]')

    expect { submit_button.click }.to change { SplitTime.count }.by(1)
    efforts = event.efforts.roster_subquery.where(actual_start_time: actual_start_time)
    efforts.each { |effort| expect(effort.actual_start_time).to eq(updated_actual_start_time_text.in_time_zone(event_group.home_time_zone)) }
  end
end
