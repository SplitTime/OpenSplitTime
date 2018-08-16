# frozen_string_literal: true

require 'rails_helper'
include FeatureMacros

RSpec.describe 'visit the podium page' do
  before(:context) do
    create_hardrock_event
  end

  after(:context) do
    clean_up_database
  end

  let(:event) { Event.first }
  let(:efforts) { event.efforts_ranked }

  context 'The event has a template selected' do
    before do
      event.update(podium_template: :ramble)
    end

    scenario 'A visitor views the podium page' do
      visit podium_event_path(event)

      expect(page).to have_content(event.name)
      efforts.first(3).each do |effort|
        expect(page).to have_content(effort.full_name)
      end
    end
  end

  context 'The event has no template selected' do
    before do
      event.update(podium_template: nil)
    end

    scenario 'A visitor views the podium page' do
      visit podium_event_path(event)

      expect(page).to have_content(event.name)
      expect(page).to have_content('The organizer has not specified a podium template')
      efforts.first(3).each do |effort|
        expect(page).not_to have_content(effort.full_name)
      end
    end
  end
end
