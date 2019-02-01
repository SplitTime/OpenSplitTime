# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'search the event group index' do
  let(:user) { users(:third_user) }
  let(:admin) { users(:admin_user) }

  let(:concealed_event_group) { event_groups(:rufa_2017) }
  let(:concealed_event) { concealed_event_group.events.first }
  let(:visible_event_groups) { event_groups - [concealed_event_group].sort_by(&:name) }
  let(:visible_event_group_1) { visible_event_groups.first }
  let(:visible_event_group_2) { visible_event_groups.second }
  let(:visible_event_1) { visible_event_group_1.events.first }
  let(:visible_event_2) { visible_event_group_2.events.first }

  before { concealed_event_group.update(concealed: true) }

  scenario 'The user is a visitor searching for a visible event or event group' do
    visit event_groups_path

    fill_in 'Event name', with: visible_event_group_1.name
    click_button 'event-group-lookup-submit'

    expect(page).to have_content(visible_event_group_1.name)
    expect(page).not_to have_content(visible_event_group_2.name)
    expect(page).not_to have_content(concealed_event_group.name)

    fill_in 'Event name', with: visible_event_1.name
    click_button 'event-group-lookup-submit'

    expect(page).to have_content(visible_event_group_1.name)
    expect(page).not_to have_content(visible_event_group_2.name)
    expect(page).not_to have_content(concealed_event_group.name)
  end

  scenario 'The user is a visitor searching for a concealed event or event group' do
    visit event_groups_path

    fill_in 'Event name', with: concealed_event_group.name
    click_button 'event-group-lookup-submit'

    expect(page).not_to have_content(visible_event_group_1.name)
    expect(page).not_to have_content(visible_event_group_2.name)
    expect(page).not_to have_content(concealed_event_group.name)

    fill_in 'Event name', with: concealed_event.name
    click_button 'event-group-lookup-submit'

    expect(page).not_to have_content(visible_event_group_1.name)
    expect(page).not_to have_content(visible_event_group_2.name)
    expect(page).not_to have_content(concealed_event_group.name)
  end

  scenario 'The user is a user searching for a visible event or event group' do
    login_as user, scope: :user

    visit event_groups_path

    fill_in 'Event name', with: visible_event_group_1.name
    click_button 'event-group-lookup-submit'

    expect(page).to have_content(visible_event_group_1.name)
    expect(page).not_to have_content(visible_event_group_2.name)
    expect(page).not_to have_content(concealed_event_group.name)

    fill_in 'Event name', with: visible_event_1.name
    click_button 'event-group-lookup-submit'

    expect(page).to have_content(visible_event_group_1.name)
    expect(page).not_to have_content(visible_event_group_2.name)
    expect(page).not_to have_content(concealed_event_group.name)
  end

  scenario 'The user is a user searching for a concealed event or event group that is not visible to the user' do
    login_as user, scope: :user

    visit event_groups_path

    fill_in 'Event name', with: concealed_event_group.name
    click_button 'event-group-lookup-submit'

    expect(page).not_to have_content(visible_event_group_1.name)
    expect(page).not_to have_content(visible_event_group_2.name)
    expect(page).not_to have_content(concealed_event_group.name)

    fill_in 'Event name', with: concealed_event.name
    click_button 'event-group-lookup-submit'

    expect(page).not_to have_content(visible_event_group_1.name)
    expect(page).not_to have_content(visible_event_group_2.name)
    expect(page).not_to have_content(concealed_event_group.name)
  end

  scenario 'The user is a user searching for a concealed event or event group that is visible to the user' do
    login_as admin, scope: :user

    visit event_groups_path

    fill_in 'Event name', with: concealed_event_group.name
    click_button 'event-group-lookup-submit'

    expect(page).not_to have_content(visible_event_group_1.name)
    expect(page).not_to have_content(visible_event_group_2.name)
    expect(page).to have_content(concealed_event_group.name)

    fill_in 'Event name', with: concealed_event.name
    click_button 'event-group-lookup-submit'

    expect(page).not_to have_content(visible_event_group_1.name)
    expect(page).not_to have_content(visible_event_group_2.name)
    expect(page).to have_content(concealed_event_group.name)
  end

  scenario 'The user is a searching for an event or event group using a lowercase search term' do
    visit event_groups_path

    fill_in 'Event name', with: visible_event_group_1.name.downcase
    click_button 'event-group-lookup-submit'

    expect(page).to have_content(visible_event_group_1.name)
    expect(page).not_to have_content(visible_event_group_2.name)
    expect(page).not_to have_content(concealed_event_group.name)

    fill_in 'Event name', with: visible_event_1.name.downcase
    click_button 'event-group-lookup-submit'

    expect(page).to have_content(visible_event_group_1.name)
    expect(page).not_to have_content(visible_event_group_2.name)
    expect(page).not_to have_content(concealed_event_group.name)
  end

  scenario 'The user is a searching for an event or event group using only a portion of the name' do
    visit event_groups_path

    fill_in 'Event name', with: visible_event_group_1.name.split.last(2).join(' ')
    click_button 'event-group-lookup-submit'

    expect(page).to have_content(visible_event_group_1.name)
    expect(page).not_to have_content(visible_event_group_2.name)
    expect(page).not_to have_content(concealed_event_group.name)

    fill_in 'Event name', with: visible_event_1.name.split.last(2).join(' ')
    click_button 'event-group-lookup-submit'

    expect(page).to have_content(visible_event_group_1.name)
    expect(page).not_to have_content(visible_event_group_2.name)
    expect(page).not_to have_content(concealed_event_group.name)
  end
end
