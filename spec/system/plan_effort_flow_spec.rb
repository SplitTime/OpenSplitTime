# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'visit the plan efforts page and plan an effort' do
  let(:user) { users(:third_user) }
  let(:admin) { users(:admin_user) }
  let(:course) { courses(:hardrock_ccw) }

  scenario 'The user is a visitor' do
    visit plan_effort_course_path(course)
    fill_in 'hh:mm', with: '38:00'
    click_button 'Create my plan'

    expect(page).to have_content(course.name)
    course.splits.each do |split|
      expect(page).to have_content(split.base_name)
    end
  end

  scenario 'The user is a user' do
    login_as user, scope: :user

    visit plan_effort_course_path(course)
    fill_in 'hh:mm', with: '38:00'
    click_button 'Create my plan'

    expect(page).to have_content(course.name)
    course.splits.each do |split|
      expect(page).to have_content(split.base_name)
    end
  end

  scenario 'The user is an admin' do
    login_as admin, scope: :user

    visit plan_effort_course_path(course)
    fill_in 'hh:mm', with: '38:00'
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

  scenario 'The course has had no events held on it' do
    course = create(:course)
    visit plan_effort_course_path(course)

    expect(page).to have_content('No events have been held on this course.')
  end
end
