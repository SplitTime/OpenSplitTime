# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'search the event index' do
  let(:user) { create(:user) }
  let(:admin) { create(:admin) }
  let!(:visible_event_1) { create(:event, event_group: visible_event_group) }
  let!(:visible_event_2) { create(:event, event_group: visible_event_group) }
  let!(:concealed_event) { create(:event, event_group: concealed_event_group) }
  let(:visible_event_group) { create(:event_group, concealed: false) }
  let(:concealed_event_group) { create(:event_group, concealed: true) }

  scenario 'The user is a visitor searching for a visible event' do
    visit events_path
    fill_in 'Event name', with: visible_event_1.name
    click_button 'Find an event'

    expect(page).to have_content(visible_event_1.name)
    expect(page).not_to have_content(visible_event_2.name)
    expect(page).not_to have_content(concealed_event.name)
  end

  scenario 'The user is a visitor searching for a concealed event' do
    visit events_path
    fill_in 'Event name', with: concealed_event.name
    click_button 'Find an event'

    expect(page).not_to have_content(visible_event_1.name)
    expect(page).not_to have_content(visible_event_2.name)
    expect(page).not_to have_content(concealed_event.name)
  end

  scenario 'The user is a user searching for a visible event' do
    login_as user, scope: :user

    visit events_path
    fill_in 'Event name', with: visible_event_1.name
    click_button 'Find an event'

    expect(page).to have_content(visible_event_1.name)
    expect(page).not_to have_content(visible_event_2.name)
    expect(page).not_to have_content(concealed_event.name)
  end

  scenario 'The user is a user searching for a concealed event that is not visible to the user' do
    login_as user, scope: :user

    visit events_path
    fill_in 'Event name', with: concealed_event.name
    click_button 'Find an event'

    expect(page).not_to have_content(visible_event_1.name)
    expect(page).not_to have_content(visible_event_2.name)
    expect(page).not_to have_content(concealed_event.name)
  end

  scenario 'The user is a user searching for a concealed event that is visible to the user' do
    login_as admin, scope: :user

    visit events_path
    fill_in 'Event name', with: concealed_event.name
    click_button 'Find an event'

    expect(page).not_to have_content(visible_event_1.name)
    expect(page).not_to have_content(visible_event_2.name)
    expect(page).to have_content(concealed_event.name)
  end
end
