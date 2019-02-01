# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'visit an event group roster page and try various features' do
  let(:user) { users(:third_user) }
  let(:owner) { users(:fourth_user) }
  let(:steward) { users(:fifth_user) }
  let(:admin) { users(:admin_user) }

  before do
    organization.update(created_by: owner.id)
    organization.stewards << steward
  end

  let(:event_group) { event_groups(:rufa_2017) }
  let(:organization) { event_group.organization }
  let(:all_efforts) { event_group.efforts }
  let(:effort_1) { all_efforts.order(:last_name).take }
  let(:other_efforts) { all_efforts.where.not(id: effort_1.id) }

  scenario 'The user is an admin' do
    login_as admin, scope: :user
    visit roster_event_group_path(event_group)
    verify_links_present
  end

  scenario 'The user is the owner of the organization' do
    login_as owner, scope: :user
    visit roster_event_group_path(event_group)
    verify_links_present
  end

  scenario 'The user is a steward of the event_group' do
    login_as steward, scope: :user
    visit roster_event_group_path(event_group)
    verify_links_present
  end

  scenario 'The user searches for a name' do
    login_as admin, scope: :user
    visit roster_event_group_path(event_group)
    verify_links_present

    fill_in 'Bib #, first name, last name, state, or country', with: effort_1.full_name
    search_button.click

    verify_single_link_present

    fill_in 'Bib #, first name, last name, state, or country', with: effort_1.bib_number
    search_button.click

    verify_single_link_present
  end

  def search_button
    find('[type=submit]')
  end

  def verify_links_present
    expect(page).to have_content(event_group.name)
    all_efforts.each { |effort| expect(page).to have_link(effort.full_name, href: effort_path(effort)) }
  end

  def verify_single_link_present
    expect(page).to have_link(effort_1.full_name, href: effort_path(effort_1))
    other_efforts.each { |effort| expect(page).not_to have_content(effort.full_name) }
  end
end
