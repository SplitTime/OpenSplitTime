require 'rails_helper'

RSpec.feature 'Event staging app flow', js: true do
  let(:user) { create(:user) }
  let(:organization_name) { build_stubbed(:organization).name }
  let(:course_name) { build_stubbed(:course).name }
  let(:event_name) { build_stubbed(:event).name }

  scenario 'Create a new Event with a new Organization and Course' do
    login_as user
    visit event_staging_app_path('new')

    expect(page).to have_content('Create Event')

    click_button 'Add New Organization'
    fill_in 'organization-name-field', with: organization_name
    fill_in class: 'js-date', with: FFaker::Time.date.split.first
    fill_in class: 'js-time', with: FFaker::Time.datetime.split.second
    select ActiveSupport::TimeZone.all.shuffle.first.name, from: 'time-zone-select'
    fill_in 'event-name-field', with: event_name
    click_button 'Add New Course'
    fill_in 'course-name-field', with: course_name
    fill_in 'course-distance-field', with: rand(10..200) / 2.0
    fill_in 'vert-gain-field', with: rand(1000..5000)
    fill_in 'vert-loss-field', with: rand(1000..5000)
    fill_in 'course-description-field', with: FFaker::HipsterIpsum.phrase
    find_by_id('continue-bottom-1').click
    wait_for_ajax

    expect(Organization.count).to eq(1)
    expect(Course.count).to eq(1)
    expect(EventGroup.count).to eq(1)
    expect(Event.count).to eq(1)
    expect(Split.count).to eq(2)
    expect(AidStation.count).to eq(2)

    organization = Organization.first
    expect(organization.name).to eq(organization_name)
    expect(organization.slug).to eq(organization.name.parameterize)

    course = Course.first
    expect(course.name).to eq(course_name)
    expect(course.slug).to eq(course.name.parameterize)

    event_group = EventGroup.first
    expect(event_group.name).to eq(event_name)
    expect(event_group.slug).to eq(event_group.name.parameterize)

    event = Event.first
    expect(event.name).to eq(event_name)
    expect(event.slug).to eq(event.name.parameterize)
  end

  scenario 'Create a new event with an existing Organization and Course' do
    organization = create(:organization, created_by: user.id)
    course = create(:course, created_by: user.id)

    login_as user
    visit event_staging_app_path('new')

    select organization.name, from: 'organization-select'

  end
end
