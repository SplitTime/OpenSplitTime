# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Create a new event series' do
  let(:owner) { users(:fourth_user) }
  let(:steward) { users(:fifth_user) }
  let(:admin) { users(:admin_user) }

  before do
    organization.update(created_by: owner.id)
    organization.stewards << steward
  end

  let(:organization) { organizations(:dirty_30_running) }
  let(:event_1) { events(:ggd30_12m) }
  let(:event_2) { events(:sum_100k) }
  let(:new_event_series_name) { 'Test Event Series' }

  scenario 'The user owns the organization' do
    login_as owner, scope: :user
    create_and_verify_series
  end

  scenario 'The user is a steward' do
    login_as steward, scope: :user
    create_and_verify_series
  end

  scenario 'The user is an admin' do
    login_as admin, scope: :user
    create_and_verify_series
  end

  private

  def create_and_verify_series
    visit organization_path(organization)
    click_link 'Event Series'
    click_link 'add-event-series'

    expect(page).to have_content('New Event Series')
    expect(page).to have_button('Create Event Series')

    fill_in 'Event series name', with: new_event_series_name
    [event_1, event_2].each do |event|
      page.check "event_series[event_ids[#{event.id}]]"
    end

    expect { click_button 'Create Event Series' }.to change { EventSeries.count }.by(1)
    new_event_series = EventSeries.last
    expect(new_event_series.name).to eq(new_event_series_name)
  end
end
