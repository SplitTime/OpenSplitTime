require 'rails_helper'

xfeature 'Event staging app flow' do
  let(:user) { create(:user) }

  scenario 'Create a new event in the Event Staging app' do
    login_as user, scope: :user
    visit event_staging_app_path('new')

    expect(page).to have_content('Create Event')

    click_button 'Add New Organization'
  end
end
