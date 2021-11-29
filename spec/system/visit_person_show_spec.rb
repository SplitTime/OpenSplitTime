# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'visit a person show page' do
  let(:person) { people(:finished_first_utah_us) }
  let(:user) { users(:third_user) }
  let(:admin) { users(:admin_user) }

  context 'When the person is visible' do
    scenario 'Visit the page' do
      visit person_path(person)

      verify_content_present
    end

    scenario 'The user is a non-admin' do
      login_as user, scope: :user
      visit person_path(person)

      verify_content_present
    end

    scenario 'The user is an admin user' do
      login_as admin, scope: :user
      visit person_path(person)

      verify_content_present
    end
  end

  context 'When the person is hidden' do
    before { person.update(concealed: true) }
    scenario 'The user is a visitor' do
      verify_record_not_found
    end

    scenario 'The user is a non-admin' do
      login_as user, scope: user

      verify_record_not_found
    end

    scenario 'The user is an admin user' do
      login_as admin, scope: :user
      visit person_path(person)

      verify_content_present
    end
  end

  def verify_page_header
    expect(page).to have_content(person.full_name)
    expect(page).to have_link('People', href: people_path)
  end

  def verify_efforts
    person.efforts.each { |effort| verify_link_present(effort, :event_name) }
  end

  def verify_content_present
    verify_page_header
    expect(person.efforts.visible.size).to eq(1)
    verify_efforts
  end

  def verify_record_not_found
    expect { visit person_path(person) }.to raise_error ::ActiveRecord::RecordNotFound
  end
end
