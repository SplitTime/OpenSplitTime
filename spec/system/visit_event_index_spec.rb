require 'rails_helper'

RSpec.describe 'Visit the events index' do
  let(:user) { create(:user) }
  let(:owner) { create(:user) }
  let(:steward) { create(:user) }
  let(:admin) { create(:admin) }
  let!(:visible_event) { create(:event, event_group: visible_event_group) }
  let!(:concealed_event) { create(:event, event_group: concealed_event_group, created_by: owner.id) }
  let(:visible_event_group) { create(:event_group, concealed: false) }
  let(:concealed_event_group) { create(:event_group, concealed: true, organization: organization) }
  let(:organization) { create(:organization) }
  before do
    organization.stewards << steward
  end

  scenario 'The user is a visitor' do
    visit events_path

    expect(page).to have_content('Events')
    expect(page).to have_content(visible_event.name)
    expect(page).not_to have_content(concealed_event.name)
  end

  scenario 'The user is a non-admin user that did not create the concealed event' do
    login_as user, scope: :user
    visit events_path

    expect(page).to have_content('Events')
    expect(page).to have_content(visible_event.name)
    expect(page).not_to have_content(concealed_event.name)
  end

  scenario 'The user is a non-admin user that created the concealed event' do
    login_as owner, scope: :user
    visit events_path

    expect(page).to have_content('Events')
    expect(page).to have_content(visible_event.name)
    expect(page).to have_content(concealed_event.name)
  end

  scenario 'The user is a non-admin user that is a steward of the concealed event' do
    login_as steward, scope: :user
    visit events_path

    expect(page).to have_content('Events')
    expect(page).to have_content(visible_event.name)
    expect(page).to have_content(concealed_event.name)
  end

  scenario 'The user is an admin user' do
    login_as admin, scope: :user
    visit events_path

    expect(page).to have_content('Events')
    expect(page).to have_content(visible_event.name)
    expect(page).to have_content(concealed_event.name)
  end
end
