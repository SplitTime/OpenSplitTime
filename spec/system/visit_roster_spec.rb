# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'visit a populated event show page and try various features' do
  context 'when the event has started efforts' do
    let(:user) { users(:third_user) }
    let(:owner) { User.find(event_group.created_by) }
    let(:steward) { User.find(organization.stewards.first.id) }
    let(:admin) { users(:admin_user) }

    let(:event) { Event.take }
    let(:event_group) { event.event_group }
    let(:organization) { event_group.organization }
    let(:course) { event.course }
    let(:effort_1) { Effort.take }
    let(:other_efforts) { Effort.where.not(id: effort_1.id) }
    let(:all_efforts) { Effort.all }

    scenario 'The user is an admin' do
      login_as admin, scope: :user

      visit roster_event_group_path(event_group)

      expect(page).to have_content(event_group.name)
      expect(all_efforts.size).to eq(8)
      all_efforts.each { |effort| expect(page).to have_content(effort.full_name) }
    end

    scenario 'The user is the owner of the event_group' do
      login_as owner, scope: :user

      visit roster_event_group_path(event_group)

      expect(page).to have_content(event_group.name)
      expect(all_efforts.size).to eq(8)
      all_efforts.each { |effort| expect(page).to have_content(effort.full_name) }
    end

    scenario 'The user is a steward of the event_group' do
      login_as steward, scope: :user

      visit roster_event_group_path(event_group)

      expect(page).to have_content(event_group.name)
      expect(all_efforts.size).to eq(8)
      all_efforts.each { |effort| expect(page).to have_content(effort.full_name) }
    end

    scenario 'The user searches for a name' do
      login_as admin, scope: :user

      visit roster_event_group_path(event_group)

      expect(page).to have_content(event_group.name)
      event.efforts.each { |effort| expect(page).to have_content(effort.full_name) }

      fill_in 'Bib #, first name, last name, state, or country', with: effort_1.full_name
      search_button.click

      expect(page).to have_content(effort_1.full_name)
      other_efforts.each { |effort| expect(page).not_to have_content(effort.full_name) }

      fill_in 'Bib #, first name, last name, state, or country', with: effort_1.bib_number
      search_button.click

      expect(page).to have_content(effort_1.full_name)
      other_efforts.each { |effort| expect(page).not_to have_content(effort.full_name) }
    end
  end

  def search_button
    find('[type=submit]')
  end
end
