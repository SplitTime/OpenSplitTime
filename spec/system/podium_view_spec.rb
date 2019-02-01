# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'visit the podium page' do
  let(:user) { users(:third_user) }
  let(:admin) { users(:admin_user) }
  let(:event) { events(:hardrock_2015) }
  let(:subject_efforts) { event.ranked_efforts }

  context 'The event has a template selected' do
    before { event.update(podium_template: :simple) }

    scenario 'A visitor views the podium page' do
      visit podium_event_path(event)
      verify_podium_view
    end

    scenario 'A user views the podium page' do
      login_as user, scope: :user

      visit podium_event_path(event)
      verify_podium_view
    end

    scenario 'An admin views the podium page' do
      login_as admin, scope: :user

      visit podium_event_path(event)
      verify_podium_view
    end
  end

  context 'The event has no template selected' do
    before { event.update(podium_template: nil) }

    scenario 'A visitor views the podium page' do
      visit podium_event_path(event)

      expect(page).to have_content(event.name)
      expect(page).to have_content('The organizer has not specified a podium template')
      subject_efforts.each do |effort|
        expect(page).not_to have_content(effort.full_name)
      end
    end
  end

  def verify_podium_view
    expect(page).to have_content(event.name)

    male_placers, male_non_placers = subject_efforts.select(&:male?).partition { |effort| effort.gender_rank < 4 }
    female_placers, female_non_placers = subject_efforts.select(&:female?).partition { |effort| effort.gender_rank < 4 }

    male_placers.each { |effort| expect(page).to have_content(effort.full_name) }
    female_placers.each { |effort| expect(page).to have_content(effort.full_name) }
    male_non_placers.each { |effort| expect(page).not_to have_content(effort.full_name) }
    female_non_placers.each { |effort| expect(page).not_to have_content(effort.full_name) }
  end
end
