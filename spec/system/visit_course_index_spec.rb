# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Visit the course index' do
  let(:user) { users(:third_user) }
  let(:admin) { users(:admin_user) }

  scenario 'The user is a visitor' do
    visit courses_path
    expect(current_path).to eq root_path
  end

  scenario 'The user is a non-admin user' do
    login_as user, scope: :user
    visit courses_path
    expect(current_path).to eq root_path
  end

  scenario 'The user is an admin user' do
    login_as admin, scope: :user
    visit courses_path

    verify_courses_present
  end

  def verify_courses_present
    Course.all.each do |course|
      expect(page).to have_content(course.name)
    end
  end
end
