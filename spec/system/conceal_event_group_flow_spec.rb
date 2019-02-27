# frozen_string_literal: true

require 'rails_helper'

# Skipped pending resolution of transactional fixtures issue. The changes to the database are rolled back
# after the redirect, so there seems to be no way to test that they are being made.

RSpec.xdescribe 'conceal and unconceal an event group using the settings page', type: :system, js: true do
  let(:admin) { users(:admin_user) }

  let(:event_group) { event_groups(:ramble) }
  let(:organization) { event_group.organization }

  context 'when event start times have the same date as UTC date' do
    scenario 'The user is a steward of the organization' do
      login_as admin, scope: :user

      visit event_group_path(event_group, force_settings: true)

      expect(event_group).not_to be_concealed
      expect(organization).not_to be_concealed
      people = Person.where(id: Effort.select(:person_id).where(event_id: event_group.events))
      people.each { |person| expect(person).not_to be_concealed }

      click_link 'Make private'
      accept_alert

      expect(page.find('.ost-toolbar')).to have_link('Make public')

      expect(event_group).to be_concealed
      expect(organization).to be_concealed
      people.each do |person|
        if person.efforts.size > 1
          expect(person).not_to be_concealed
        else
          expect(person).to be_concealed
        end
      end
    end
  end
end
