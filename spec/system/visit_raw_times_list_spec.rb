# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'visit an event group raw times list page and try various features' do
  let(:user) { users(:third_user) }
  let(:owner) { users(:fourth_user) }
  let(:steward) { users(:fifth_user) }
  let(:admin) { users(:admin_user) }

  before do
    organization.update(created_by: owner.id)
    organization.stewards << steward
  end

  let(:event_group) { event_groups(:sum) }
  let(:organization) { event_group.organization }

  let(:all_raw_times) { event_group.raw_times.first(25) }
  let(:raw_times_114) { event_group.raw_times.where(bib_number: '114') }
  let(:raw_times_101) { event_group.raw_times.where(bib_number: '101') }
  let(:stopped_raw_times) { event_group.raw_times.where(stopped_here: true) }
  let(:unstopped_raw_times) { event_group.raw_times.where(stopped_here: false).first(5) }

  scenario 'The user is an admin' do
    login_as admin, scope: :user
    visit raw_times_event_group_path(event_group)
    verify_content_present(event_group)
    verify_raw_times_present(all_raw_times)
  end

  scenario 'The user is the owner of the organization' do
    login_as owner, scope: :user
    visit raw_times_event_group_path(event_group)
    verify_content_present(event_group)
    verify_raw_times_present(all_raw_times)
  end

  scenario 'The user is a steward of the event_group' do
    login_as steward, scope: :user
    visit raw_times_event_group_path(event_group)
    verify_content_present(event_group)
    verify_raw_times_present(all_raw_times)
  end

  scenario 'The user searches for a bib number' do
    login_as admin, scope: :user
    visit raw_times_event_group_path(event_group)
    verify_raw_times_present(all_raw_times)

    fill_in 'Bib #', with: '101'
    search_button.click

    verify_raw_times_present(raw_times_101)
    verify_raw_times_absent(raw_times_114)
  end

  scenario 'The user filters using the stopped selector' do
    login_as admin, scope: :user
    visit raw_times_event_group_path(event_group)
    verify_raw_times_present(all_raw_times)

    click_link 'Stopped'

    verify_raw_times_present(stopped_raw_times)
    verify_raw_times_absent(unstopped_raw_times)
  end

  def search_button
    find('[type=submit]')
  end

  def verify_raw_times_present(raw_times)
    raw_times.each do |raw_time|
      row = page.find("#raw_time_#{raw_time.id}")
      expect(row).to have_content(raw_time.bib_number)
    end
  end

  def verify_raw_times_absent(raw_times)
    raw_times.each do |raw_time|
      expect(page).not_to have_selector("#raw_time_#{raw_time.id}")
    end
  end
end
