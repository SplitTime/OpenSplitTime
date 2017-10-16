require 'rails_helper'
include FeatureMacros

RSpec.feature 'visit a populated event show page and try various features' do
  context 'when the event has started efforts' do
    before(:context) do
      create_hardrock_event
    end

    after(:context) do
      clean_up_database
    end

    let(:user) { create(:user) }
    let(:owner) { create(:user) }
    let(:steward) { create(:user) }
    let(:admin) { create(:admin) }

    let(:event) { Event.first }
    let(:course) { Course.first }
    let(:effort_1) { Effort.first }
    let(:other_efforts) { Effort.where.not(id: effort_1.id) }

    scenario 'The user is a visitor' do
      visit event_path(event)

      expect(page).to have_content(event.name)
      expect(page).to have_link('Full spread', href: spread_event_path(event))
      expect(page).not_to have_link('Admin', href: stage_event_path(event))
      expect(page).not_to have_link('Event Staging')
      expect(page).not_to have_link('Settings', href: event_group_path(event.event_group))
      expect(page).to have_link('Plan my effort', href: plan_effort_course_path(course))
      expect(page).to have_link('All-time best efforts', href: best_efforts_course_path(course))
    end

    scenario 'The user is a user who did not create the event and is not a steward' do
      login_as user, scope: :user
      visit event_path(event)

      expect(page).to have_content(event.name)
      expect(page).to have_link('Full spread', href: spread_event_path(event))
      expect(page).not_to have_link('Admin', href: stage_event_path(event))
      expect(page).not_to have_link('Event Staging')
      expect(page).not_to have_link('Settings', href: event_group_path(event.event_group))
      expect(page).to have_link('Plan my effort', href: plan_effort_course_path(course))
      expect(page).to have_link('All-time best efforts', href: best_efforts_course_path(course))
    end

    scenario 'The user is a user who created the event' do
      event = Event.first
      event.update(created_by: owner.id)
      event_group = event.event_group
      event_group.update(created_by: owner.id)

      login_as owner, scope: :user
      visit event_path(event)

      expect(page).to have_content(event.name)
      expect(page).to have_link('Full spread', href: spread_event_path(event))
      expect(page).to have_link('Admin', href: stage_event_path(event))
      expect(page).to have_link('Event Staging')
      expect(page).to have_link('Settings', href: event_group_path(event.event_group))
      expect(page).to have_link('Plan my effort', href: plan_effort_course_path(course))
      expect(page).to have_link('All-time best efforts', href: best_efforts_course_path(course))
    end

    scenario 'The user is a steward of the organization related to the event' do
      event = Event.first
      organization = event.event_group.organization
      organization.stewards << steward

      login_as steward, scope: :user
      visit event_path(event)

      expect(page).to have_content(event.name)
      expect(page).to have_link('Full spread', href: spread_event_path(event))
      expect(page).to have_link('Admin', href: stage_event_path(event))
      expect(page).to have_link('Event Staging')
      expect(page).not_to have_link('Settings', href: event_group_path(event.event_group))
      expect(page).to have_link('Plan my effort', href: plan_effort_course_path(course))
      expect(page).to have_link('All-time best efforts', href: best_efforts_course_path(course))
    end

    scenario 'The user is an admin' do
      login_as admin, scope: :user
      visit event_path(event)

      expect(page).to have_content(event.name)
      expect(page).to have_link('Full spread', href: spread_event_path(event))
      expect(page).to have_link('Admin', href: stage_event_path(event))
      expect(page).to have_link('Event Staging')
      expect(page).to have_link('Settings', href: event_group_path(event.event_group))
      expect(page).to have_link('Plan my effort', href: plan_effort_course_path(course))
      expect(page).to have_link('All-time best efforts', href: best_efforts_course_path(course))
    end

    scenario 'The user searches for a name' do
      visit event_path(event)

      expect(page).to have_content(event.name)
      event.efforts.each do |effort|
        expect(page).to have_content(effort.full_name)
      end

      fill_in 'Bib #, first name, last name, state, or country', with: effort_1.full_name
      click_button 'Find someone'

      expect(page).to have_content(effort_1.full_name)
      other_efforts.each do |effort|
        expect(page).not_to have_content(effort.full_name)
      end

      fill_in 'Bib #, first name, last name, state, or country', with: effort_1.bib_number
      click_button 'Find someone'

      expect(page).to have_content(effort_1.full_name)
      other_efforts.each do |effort|
        expect(page).not_to have_content(effort.full_name)
      end
    end
  end

  context 'when the event has only unstarted efforts' do
    let!(:event) { create(:event) }
    let!(:efforts) { create_list(:effort, 3, :with_bib_number, event: event) }
    let(:effort_1) { efforts.first }
    let(:other_efforts) { Effort.where.not(id: effort_1.id) }

    scenario 'User visits the page and searches for a name' do
      visit event_path(event)

      efforts.each do |effort|
        expect(page).to have_content(effort.name)
      end

      fill_in 'Bib #, first name, last name, state, or country', with: effort_1.full_name
      click_button 'Find someone'

      expect(page).to have_content(effort_1.full_name)
      other_efforts.each do |effort|
        expect(page).not_to have_content(effort.full_name)
      end

      fill_in 'Bib #, first name, last name, state, or country', with: effort_1.bib_number
      click_button 'Find someone'

      expect(page).to have_content(effort_1.full_name)
      other_efforts.each do |effort|
        expect(page).not_to have_content(effort.full_name)
      end
    end
  end
end
