require 'rails_helper'

RSpec.feature 'Event staging app flow', js: true do
  let(:user) { create(:user) }

  # Build stubbed resources purely to get random attributes for fields
  let(:stubbed_org) { build_stubbed(:organization) }
  let(:stubbed_course) { build_stubbed(:course, :with_description) }
  let(:stubbed_event) { build_stubbed(:event) }

  scenario 'Create a new Event with a new Organization and Course' do
    login_as user
    visit event_staging_app_path('new')

    expect(page).to have_content('Create Event')
    continue_button = find_by_id('continue-bottom-1')
    expect(continue_button[:disabled]&.to_boolean).to be_truthy

    click_button 'Add New Organization'
    fill_in 'organization-name-field', with: stubbed_org.name
    fill_in class: 'js-date', with: stubbed_event.start_time.strftime('%m/%d/%Y')
    fill_in class: 'js-time', with: stubbed_event.start_time.strftime('%H:%M')
    select stubbed_event.home_time_zone, from: 'time-zone-select'
    fill_in 'event-name-field', with: stubbed_event.name
    click_button 'Add New Course'
    fill_in 'course-name-field', with: stubbed_course.name
    fill_in 'course-distance-field', with: stubbed_event.name.split.last
    fill_in 'course-vert-gain-field', with: rand(1000..5000)
    fill_in 'course-vert-loss-field', with: rand(1000..5000)
    fill_in 'course-description-field', with: stubbed_course.description

    expect(continue_button[:disabled]&.to_boolean).to be_falsey
    continue_button.click
    wait_for_ajax

    expect(Organization.count).to eq(1)
    expect(Course.count).to eq(1)
    expect(Split.count).to eq(2)
    expect(EventGroup.count).to eq(1)
    expect(Event.count).to eq(1)
    expect(AidStation.count).to eq(2)

    organization = Organization.first
    expect(organization.name).to eq(stubbed_org.name)
    expect(organization.slug).to eq(organization.name.parameterize)

    course = Course.first
    expect(course.name).to eq(stubbed_course.name)
    expect(course.slug).to eq(course.name.parameterize)

    event_group = EventGroup.first
    expect(event_group.name).to eq(stubbed_event.name)
    expect(event_group.slug).to eq(event_group.name.parameterize)

    event = Event.first
    expect(event.name).to eq(stubbed_event.name)
    expect(event.slug).to eq(event.name.parameterize)
  end

  scenario 'Create a new event with an existing Organization and Course' do
    organization = create(:organization, created_by: user.id)
    course = create(:course_with_standard_splits, :with_description, created_by: user.id)

    expect(Organization.count).to eq(1)
    expect(Course.count).to eq(1)
    expect(Split.count).to eq(4)
    expect(EventGroup.count).to eq(0)
    expect(Event.count).to eq(0)
    expect(AidStation.count).to eq(0)

    login_as user
    visit event_staging_app_path('new')

    continue_button = find_by_id('continue-bottom-1')
    expect(continue_button[:disabled]&.to_boolean).to be_truthy

    expect(page).not_to have_field('organization-name-field')
    select organization.name, from: 'organization-select'
    expect(page).to have_field('organization-name-field', with: organization.name)

    fill_in class: 'js-date', with: stubbed_event.start_time.strftime('%m/%d/%Y')
    fill_in class: 'js-time', with: stubbed_event.start_time.strftime('%H:%M')
    select stubbed_event.home_time_zone, from: 'time-zone-select'
    fill_in 'event-name-field', with: stubbed_event.name

    expect(page).not_to have_field('course-name-field')
    select course.name, from: 'course-select'
    expect(page).to have_field('course-name-field', with: course.name)
    expect(page).to have_field('course-distance-field', with: course.finish_split.distance_from_start.meters.to.miles.round(2))
    expect(page).to have_field('course-vert-gain-field', with: course.finish_split.vert_gain_from_start.meters.to.feet.round(1))
    expect(page).to have_field('course-vert-loss-field', with: course.finish_split.vert_loss_from_start.meters.to.feet.round(1))
    expect(page).to have_field('course-description-field', with: course.description)

    expect(continue_button[:disabled]&.to_boolean).to be_falsey
    continue_button.click
    wait_for_ajax

    expect(Organization.count).to eq(1)
    expect(Course.count).to eq(1)
    expect(Split.count).to eq(4)
    expect(EventGroup.count).to eq(1)
    expect(Event.count).to eq(1)
    expect(AidStation.count).to eq(4)

    event_group = EventGroup.first
    expect(event_group.name).to eq(stubbed_event.name)
    expect(event_group.slug).to eq(event_group.name.parameterize)

    event = Event.first
    expect(event.name).to eq(stubbed_event.name)
    expect(event.slug).to eq(event.name.parameterize)
  end

  scenario 'Edit a previously created event' do
    organization = create(:organization, created_by: user.id)
    course = create(:course_with_standard_splits, :with_description, created_by: user.id)
    event_group = create(:event_group, organization: organization)
    event = create(:event, event_group: event_group, course: course)
    event.splits << course.splits

    login_as user
    visit event_staging_app_path(event)
    continue_button = find_by_id('continue-bottom-1')
    expect(continue_button[:disabled]&.to_boolean).to be_falsey

    fill_in 'event-name-field', with: 'Updated Event Name'
    fill_in class: 'js-date', with: '2017-10-01'
    fill_in class: 'js-time', with: '07:30'
    select 'Arizona', from: 'time-zone-select'

    continue_button.click
    wait_for_ajax

    event.reload
    expect(event.name).to eq('Updated Event Name')
    expect(event.start_time).to eq('2017-10-01 07:30 -07:00')
  end
end
