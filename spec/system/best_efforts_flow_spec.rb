# frozen_string_literal: true

require 'rails_helper'

# These tests will fail if the test database is rebuilt using db:schema:load
# To fix, run the following from the command line:

# rails db:structure:load RAILS_ENV=test

RSpec.describe 'Visit the best efforts page and search for an effort' do
  let(:course) { courses(:hardrock_cw) }
  let(:event) { events(:hardrock_2016) }
  let(:event_group) { event.event_group }
  let(:organization) { event_group.organization }

  let(:effort_1) { event.efforts.ranked_with_status.first }
  let(:other_efforts) { event.efforts.where.not(id: effort_1.id) }

  scenario 'Visitor visits the page and searches for a name' do
    visit best_efforts_course_path(course)

    expect(page).to have_content(course.name)
    finished_efforts = event.efforts.ranked_with_status.select(&:finished)

    finished_efforts.each { |effort| verify_link_present(effort, :full_name) }

    fill_in 'First name, last name, state, or country', with: effort_1.name
    click_button 'search-submit'
    wait_for_css

    verify_link_present(effort_1)
    other_efforts.each { |effort| verify_content_absent(effort) }
  end

  context 'when hidden efforts exist for the course' do
    let(:hidden_event) { events(:hardrock_2014) }
    let(:hidden_event_group) { hidden_event.event_group }
    let(:hidden_effort_1) { hidden_event.efforts.ranked_with_status.first }
    let(:other_hidden_efforts) { hidden_event.efforts.where.not(id: hidden_effort_1.id) }

    let(:user) { users(:third_user) }
    let(:owner) { users(:fourth_user) }
    let(:steward) { users(:fifth_user) }
    let(:admin) { users(:admin_user) }

    before do
      hidden_event_group.update(concealed: true)
      organization.update(created_by: owner.id)
      organization.stewards << steward
    end

    scenario 'The user is a visitor' do
      visit best_efforts_course_path(course)
      verify_link_present(effort_1)
      verify_content_absent(hidden_effort_1)
    end

    scenario 'The user is not the owner and not a steward' do
      login_as user, scope: :user

      visit best_efforts_course_path(course)
      verify_link_present(effort_1)
      verify_content_absent(hidden_effort_1)
    end

    scenario 'The user owns the organization' do
      login_as owner, scope: :user

      visit best_efforts_course_path(course)
      verify_link_present(effort_1)
      verify_link_present(hidden_effort_1)
    end

    scenario 'The user is a steward of the organization' do
      login_as steward, scope: :user

      visit best_efforts_course_path(course)
      verify_link_present(effort_1)
      verify_link_present(hidden_effort_1)
    end

    scenario 'The user is an admin' do
      login_as admin, scope: :user

      visit best_efforts_course_path(course)
      verify_link_present(effort_1)
      verify_link_present(hidden_effort_1)
    end
  end
end
