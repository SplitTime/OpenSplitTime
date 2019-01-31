# frozen_string_literal: true

require 'rails_helper'
include FeatureMacros

RSpec.describe 'visit the podium page' do
  let(:event) { events(:hardrock_2015) }
  let(:subject_efforts) { event.efforts_ranked }

  context 'The event has a template selected' do
    before { event.update(podium_template: :ramble) }

    scenario 'A visitor views the podium page' do
      visit podium_event_path(event)

      expect(page).to have_content(event.name)
      subject_efforts.first(3).each do |effort|
        expect(page).to have_content(effort.full_name)
      end
    end
  end

  context 'The event has no template selected' do
    before { event.update(podium_template: nil) }

    scenario 'A visitor views the podium page' do
      visit podium_event_path(event)

      expect(page).to have_content(event.name)
      expect(page).to have_content('The organizer has not specified a podium template')
      subject_efforts.first(3).each do |effort|
        expect(page).not_to have_content(effort.full_name)
      end
    end
  end
end
