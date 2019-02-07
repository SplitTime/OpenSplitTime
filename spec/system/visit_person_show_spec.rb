# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'visit a person show page' do

  context 'When the person has at least one effort' do
    let(:person) { people(:finished_first_utah_us) }

    scenario 'Visit the page' do
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
    person.efforts.each do |effort|
      expect(page).to have_link(effort.event_name, href: effort_path(effort))
    end
  end
end
