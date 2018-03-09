require 'rails_helper'

RSpec.describe 'Event staging app flow', type: :system, js: true do
  let!(:user) { create(:user) }

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
    wait_for_fill_in
    fill_in class: 'js-date', with: stubbed_event.start_time.strftime('%m/%d/%Y')
    wait_for_fill_in
    fill_in class: 'js-time', with: stubbed_event.start_time.strftime('%H:%M')
    wait_for_fill_in
    select stubbed_event.home_time_zone, from: 'time-zone-select'
    fill_in 'event-name-field', with: stubbed_event.name
    wait_for_fill_in
    click_button 'Add New Course'
    fill_in 'course-name-field', with: stubbed_course.name
    wait_for_fill_in
    fill_in 'course-distance-field', with: stubbed_event.name.split.last
    wait_for_fill_in
    fill_in 'course-vert-gain-field', with: rand(1000..5000)
    wait_for_fill_in
    fill_in 'course-vert-loss-field', with: rand(1000..5000)
    wait_for_fill_in
    fill_in 'course-description-field', with: stubbed_course.description

    expect(continue_button[:disabled]&.to_boolean).to be_falsey
    continue_button.click
    3.times { wait_for_css }
    expect(page).to have_content('Create Splits')
    wait_for_ajax

    expect(Organization.count).to eq(1)
    expect(Course.count).to eq(1)
    expect(Split.count).to eq(2)
    expect(EventGroup.count).to eq(1)
    expect(Event.count).to eq(1)

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
    # This expect passes in local environment but fails in CI
    # expect(event.aid_stations.size).to eq(2)
  end

  scenario 'Create a new event with an existing Organization and Course' do
    organization = create(:organization, created_by: user.id)
    course = create(:course_with_standard_splits, :with_description, created_by: user.id)
    course.reload

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
    wait_for_ajax
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
    3.times { wait_for_css }
    expect(page).to have_content('Create Splits')
    wait_for_ajax

    expect(Organization.count).to eq(1)
    expect(Course.count).to eq(1)
    expect(Split.count).to eq(4)
    expect(EventGroup.count).to eq(1)
    expect(Event.count).to eq(1)

    event_group = EventGroup.first
    expect(event_group.name).to eq(stubbed_event.name)
    expect(event_group.slug).to eq(event_group.name.parameterize)

    event = Event.first
    expect(event.name).to eq(stubbed_event.name)
    expect(event.slug).to eq(event.name.parameterize)
    # This expect passes in local environment but fails in CI
    # expect(event.aid_stations.size).to eq(4)
  end

  context 'when there is a previously created event' do
    let(:course) { create(:course_with_standard_splits, :with_description, created_by: user.id) }
    let(:organization) { create(:organization, created_by: user.id) }
    let(:event_group) { create(:event_group, organization: organization) }
    let(:event) { create(:event, event_group: event_group, course: course) }

    before do
      course.reload
      event.splits << course.splits
    end

    scenario 'Edit event information' do
      login_as user
      visit event_staging_app_path(event)

      continue_button = find_by_id('continue-bottom-1')
      expect(continue_button[:disabled]&.to_boolean).to be_falsey

      fill_in 'event-name-field', with: 'Updated Event Name'

      date_field = find_field(class: 'js-date')
      manually_clear_field(date_field)
      date_field.native.send_keys('10/1/2017')

      time_field = find_field(class: 'js-time')
      manually_clear_field(time_field)
      time_field.native.send_keys('07:30 am')

      select 'Arizona', from: 'time-zone-select'

      continue_button.click
      expect(page).to have_content('Create Splits')
      wait_for_ajax

      event.reload
      expect(event.name).to eq('Updated Event Name')
      expect(event.start_time).to eq('2017-10-01 07:30 -07:00')
    end

    scenario 'Add a split' do
      login_as user
      visit "#{event_staging_app_path(event)}#/splits"

      expect(Split.count).to eq(4)
      expect(AidStation.count).to eq(4)

      click_button 'Add'
      fill_in 'split-name-field', with: 'New Split Name'
      wait_for_css
      fill_in 'split-description-field', with: 'A critical aid station'
      wait_for_fill_in
      fill_in 'split-distance-field', with: '15.5'
      page.execute_script("$('#split-in-out-radio').click()")
      fill_in 'split-vert-gain-field', with: '1500'
      wait_for_fill_in
      fill_in 'split-vert-loss-field', with: '1200'
      wait_for_fill_in
      fill_in 'split-latitude-field', with: '40.1'
      wait_for_fill_in
      fill_in 'split-longitude-field', with: '-105.1'
      wait_for_fill_in
      fill_in 'split-elevation-field', with: '6000'

      click_button 'Add Split'
      wait_for_ajax

      expect(Split.count).to eq(5)
      expect(AidStation.count).to eq(5)
      split = Split.last
      expect(split.base_name).to eq('New Split Name')
      expect(split.description).to eq('A critical aid station')
      expect(split.kind).to eq('intermediate')
      expect(split.sub_split_bitmap).to eq(65)
      expect(split.distance_from_start).to eq(24944)
      expect(split.vert_gain_from_start).to be_within(1).of(457)
      expect(split.vert_loss_from_start).to be_within(1).of(365)
      expect(split.latitude).to eq(40.1)
      expect(split.longitude).to eq(-105.1)
      expect(split.elevation).to be_within(1).of(1828)
    end

    xscenario 'Add an effort' do
      # Skipped because effort-birthdate-field does not appear during testing
      # This is possibly a problem with Vue and Turbolinks

      stubbed_effort = build_stubbed(:effort, :with_geo_attributes, :with_birthdate, :with_bib_number, :with_contact_info)
      country = Carmen::Country.coded(stubbed_effort.country_code)
      login_as user
      visit "#{event_staging_app_path(event)}#/entrants"

      expect(Effort.count).to eq(0)

      click_button 'Add'
      fill_in 'effort-first-name-field', with: stubbed_effort.first_name
      wait_for_fill_in
      fill_in 'effort-last-name-field', with: stubbed_effort.last_name
      wait_for_fill_in
      page.execute_script("$('#effort-#{stubbed_effort.gender}-radio').click()")
      page.find('#effort-birthdate-field').find('.js-date').set(stubbed_effort.birthdate.strftime('%m/%d/%Y'))
      wait_for_fill_in
      fill_in 'effort-bib-number-field', with: stubbed_effort.bib_number
      select country.name, from: 'effort-country-select'
      select country.subregions.coded(stubbed_effort.state_code).name, from: 'effort-state-select'
      fill_in 'effort-city-field', with: stubbed_effort.city
      wait_for_fill_in
      fill_in 'effort-email-field', with: stubbed_effort.email
      wait_for_fill_in
      fill_in 'effort-phone-field', with: stubbed_effort.phone

      click_button 'Add Entrant'
      wait_for_ajax

      expect(Effort.count).to eq(1)
      effort = Effort.last
      [:first_name, :last_name, :gender, :birthdate, :bib_number, :city, :state_code, :country_code, :email, :phone].each do |attribute|
        expect(effort[attribute]).to eq(stubbed_effort[attribute])
      end
    end

    scenario 'Edit an existing effort' do
      effort = create(:effort, :with_geo_attributes, :with_birthdate, :with_contact_info, :with_bib_number, event: event)

      login_as user
      visit "#{event_staging_app_path(event)}#/entrants"

      expect(Effort.count).to eq(1)
      edit_link = find_link(class: 'edit')
      edit_link.click
      fill_in 'effort-first-name-field', with: 'Betty'
      wait_for_fill_in
      fill_in 'effort-bib-number-field', with: '1001'
      click_button 'Done'
      wait_for_ajax

      effort.reload
      expect(effort.first_name).to eq('Betty')
      expect(effort.bib_number).to eq(1001)
    end
  end

  def manually_clear_field(field)
    field.value.size.times { field.native.send_keys(:backspace) }
  end
end
