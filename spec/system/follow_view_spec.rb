# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'visit the follow page' do
  let(:user) { users(:third_user) }
  let(:admin) { users(:admin_user) }
  let(:event_group) { event_groups(:hardrock_2015) }

  scenario 'A visitor views the follow page' do
    visit follow_event_group_path(event_group)
    expect(page).to have_content(event_group.name)
  end

  scenario 'A user views the follow page' do
    login_as user, scope: :user

    visit follow_event_group_path(event_group)
    expect(page).to have_content(event_group.name)
  end

  scenario 'An admin views the follow page' do
    login_as admin, scope: :user

    visit follow_event_group_path(event_group)
    expect(page).to have_content(event_group.name)
  end

  context 'The event group is completed' do
    before do
      event_group.events.each do |event|
        Interactors::UpdateEffortsStop.perform!(event.efforts, stop_status: true)
      end
    end

    context 'The event group has a single event' do
      let(:event) { event_group.events.first }
      scenario 'A visitor views the follow page and is redirected to the spread' do
        visit follow_event_group_path(event_group)
        expect(current_path).to eq spread_event_path(event)
      end
    end

    context 'The event group has multiple events' do
      let(:event_group) { event_groups(:sum) }
      scenario 'A visitor views the follow page and is redirected to the event group page' do
        visit follow_event_group_path(event_group)
        expect(current_path).to eq event_group_path(event_group)
      end
    end
  end
end
