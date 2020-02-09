# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Visit an organization show page and try various features' do
  let(:user) { users(:third_user) }
  let(:owner) { users(:fourth_user) }
  let(:steward) { users(:fifth_user) }
  let(:admin) { users(:admin_user) }

  before do
    organization.update(created_by: owner.id)
    organization.stewards << steward
  end

  let(:organization) { organizations(:dirty_30_running) }
  let(:concealed_event_group) { event_groups(:sum) }
  let(:concealed_event_1) { concealed_event_group.events.first }
  let(:concealed_event_2) { concealed_event_group.events.second }
  let(:visible_event_group) { event_groups(:dirty_30) }
  let(:visible_event_1) { visible_event_group.events.first }
  let(:visible_event_2) { visible_event_group.events.second }

  let(:outside_organization) { organizations(:running_up_for_air) }
  let(:outside_event_group) { event_groups(:rufa_2017) }
  let(:outside_event_1) { outside_event_group.events.first }
  let(:outside_event_2) { outside_event_group.events.second }

  before { concealed_event_group.update(concealed: true) }
  
  scenario 'The user is a visitor' do
    visit organization_path(organization)

    verify_public_links_present
    verify_concealed_content_absent
    verify_outside_content_absent
  end

  scenario 'The user is not the owner and not a steward' do
    login_as user, scope: :user
    visit organization_path(organization)

    verify_public_links_present
    verify_concealed_content_absent
    verify_outside_content_absent
  end

  scenario 'The user owns the organization' do
    login_as owner, scope: :user
    visit organization_path(organization)

    verify_public_links_present
    verify_concealed_links_present
    verify_outside_content_absent
  end

  scenario 'The user is a steward of the organization' do
    login_as steward, scope: :user
    visit organization_path(organization)

    verify_public_links_present
    verify_concealed_links_present
    verify_outside_content_absent
  end

  scenario 'The user is an admin user' do
    login_as admin, scope: :user
    visit organization_path(organization)

    verify_public_links_present
    verify_concealed_links_present
    verify_outside_content_absent
  end

  scenario 'The user is a visitor that clicks the Courses link' do
    visit organization_path(organization)
    click_link 'Courses'

    expect(page).to have_content(visible_event_1.course.name)
    expect(page).to have_content(visible_event_2.course.name)
  end

  scenario 'The user is a visitor that clicks the Event Series link' do
    visit organization_path(organization)
    click_link 'Event Series'

    organization.event_series.each do |series|
      expect(page).to have_content(series.name)
    end
  end

  scenario 'The user is an owner that clicks the Stewards link' do
    login_as owner, scope: :user
    visit organization_path(organization)

    click_link 'Stewards'

    expect(page).to have_content(steward.full_name)
    expect(page).to have_content(steward.email)
    expect(page).to have_content('Remove')

    click_link 'Remove'

    expect(page).not_to have_content(steward.full_name)
    expect(page).to have_content('No stewards')
  end

  scenario 'The user is an admin that clicks the Stewards link' do
    login_as admin, scope: :user
    visit organization_path(organization)

    click_link 'Stewards'

    expect(page).to have_content(steward.full_name)
    expect(page).to have_content(steward.email)
    expect(page).to have_content('Remove')

    click_link 'Remove'

    expect(page).not_to have_content(steward.full_name)
    expect(page).to have_content('No stewards')
  end

  def verify_public_links_present
    expect(page).to have_content(organization.name)
    expect(page).to have_content('Courses')
    expect(page).to have_content('Events')
    expect(page).to have_content('Event Series')

    expect(page).to have_content(visible_event_group.name)
    expect(page).to have_content(visible_event_1.guaranteed_short_name)
    expect(page).to have_content(visible_event_2.guaranteed_short_name)
  end

  def verify_outside_content_absent
    expect(page).not_to have_content(outside_event_group.name)
    expect(page).not_to have_content(outside_event_1.guaranteed_short_name)
    expect(page).not_to have_content(outside_event_2.guaranteed_short_name)
  end

  def verify_concealed_content_absent
    expect(page).not_to have_content('Stewards')
    expect(page).not_to have_content(concealed_event_group.name)
    expect(page).not_to have_content(concealed_event_1.guaranteed_short_name)
    expect(page).not_to have_content(concealed_event_2.guaranteed_short_name)
  end

  def verify_concealed_links_present
    expect(page).to have_content(concealed_event_group.name)
    expect(page).to have_content(concealed_event_1.guaranteed_short_name)
    expect(page).to have_content(concealed_event_2.guaranteed_short_name)
  end
end
