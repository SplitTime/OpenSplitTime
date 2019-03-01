# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'visit the traffic page' do
  let(:user) { users(:third_user) }
  let(:admin) { users(:admin_user) }
  let(:event_group) { event_groups(:hardrock_2015) }

  scenario 'A visitor views the podium page' do
    visit traffic_event_group_path(event_group)
    expect(page).to have_content(event_group.name)
  end

  scenario 'A user views the podium page' do
    login_as user, scope: :user

    visit traffic_event_group_path(event_group)
    expect(page).to have_content(event_group.name)
  end

  scenario 'An admin views the podium page' do
    login_as admin, scope: :user

    visit traffic_event_group_path(event_group)
    expect(page).to have_content(event_group.name)
  end

  scenario 'A user changes the view using the split and bandwidth dropdowns' do
    visit traffic_event_group_path(event_group)
    expect(page).to have_content(event_group.name)
    expect(page.find('tr', text: 'Fri 06:00 to Fri 06:30')).to have_content(30)
    expect(page.find('tr', text: 'Totals')).to have_content(30)

    click_link 'Putnam'
    page.find_button('Putnam')

    expect(page.find('tr', text: 'Sat 04:00 to Sat 04:30')).to have_content(1)
    expect(page.find('tr', text: 'Totals')).to have_content(26)

    click_link('60 minutes')
    page.find_button('60 minutes')

    expect(page.find('tr', text: 'Sat 19:00 to Sat 20:00')).to have_content(4)
    expect(page.find('tr', text: 'Totals')).to have_content(26)
  end
end
