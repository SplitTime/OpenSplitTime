# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'visit a person show page' do
  let(:person) { people(:finished_first_utah_us) }
  let(:user) { users(:third_user) }
  let(:owner) { users(:fourth_user) }
  let(:steward) { users(:fifth_user) }
  let(:admin) { users(:admin_user) }

  context 'When the person is visible' do
    scenario 'Visit the page' do
      visit person_path(person)

      verify_page_header
      expect(person.efforts.visible.size).to eq(1)
      verify_efforts
    end
  end

  context 'When the person is hidden' do
    before { person.update(concealed: true) }
    scenario 'The user is a visitor and cannot see the record' do
      expect { visit person_path(person) }.to raise_error ::ActiveRecord::RecordNotFound
    end

    scenario 'The user is an admin user' do
      login_as admin, scope: :user
      visit person_path(person)

      verify_page_header
      expect(person.efforts.visible.size).to eq(1)
      verify_efforts
    end

  end

  def verify_page_header
    expect(page).to have_content(person.full_name)
    expect(page).to have_link('People', href: people_path)
  end

  def verify_efforts
    person.efforts.each { |effort| verify_link_present(effort, :event_name) }
  end
end
