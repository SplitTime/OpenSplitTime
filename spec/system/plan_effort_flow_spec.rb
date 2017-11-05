require 'rails_helper'
include FeatureMacros

RSpec.describe 'visit the plan efforts page and plan an effort' do
  before(:context) do
    create_hardrock_event
  end

  after(:context) do
    clean_up_database
  end

  let(:user) { create(:user) }
  let(:admin) { create(:admin) }
  let(:course) { Course.first }

  scenario 'The user is a visitor' do
    visit plan_effort_course_path(course)
    fill_in 'hh:mm', with: '42:00'
    click_button 'Create my plan'

    expect(page).to have_content(course.name)
    course.splits.each do |split|
      expect(page).to have_content(split.base_name)
    end
  end

  scenario 'The user is a user' do
    login_as user, scope: :user

    visit plan_effort_course_path(course)
    fill_in 'hh:mm', with: '42:00'
    click_button 'Create my plan'

    expect(page).to have_content(course.name)
    course.splits.each do |split|
      expect(page).to have_content(split.base_name)
    end
  end

  scenario 'The user enters a time outside the normal scope' do
    visit plan_effort_course_path(course)
    fill_in 'hh:mm', with: '18:00'
    click_button 'Create my plan'

    expect(page).to have_content(course.name)
    expect(page).to have_content('Insufficient data to create a plan.')
  end

  scenario 'The course has had no events run on it' do
    course = create(:course)
    visit plan_effort_course_path(course)

    expect(page).to have_content('No events have been run on this course.')
  end
end
