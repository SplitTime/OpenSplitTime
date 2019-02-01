# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Visit an organization show page and try various features' do
  let(:user) { users(:third_user) }
  let(:owner) { create(:user) }
  let(:steward) { create(:user) }
  let(:admin) { users(:admin_user) }
  let!(:visible_event_1) { create(:event, event_group: visible_event_group) }
  let!(:visible_event_2) { create(:event, event_group: visible_event_group) }
  let!(:concealed_event_1) { create(:event, event_group: concealed_event_group) }
  let!(:concealed_event_2) { create(:event, event_group: concealed_event_group) }
  let!(:outside_event_1) { create(:event, event_group: outside_event_group) }
  let!(:outside_event_2) { create(:event, event_group: outside_event_group) }
  let(:visible_event_group) { create(:event_group, concealed: false, organization: organization) }
  let(:concealed_event_group) { create(:event_group, concealed: true, organization: organization) }
  let(:outside_event_group) { create(:event_group, concealed: false, organization: outside_organization) }
  let(:organization) { create(:organization, created_by: owner.id) }
  let(:outside_organization) { create(:organization) }
  before do
    organization.stewards << steward
  end

  scenario 'The user is a visitor' do
    visit organization_path(organization)

    expect(page).to have_content(organization.name)
    expect(page).to have_content('Courses')
    expect(page).to have_content('Events')
    expect(page).not_to have_content('Stewards')

    expect(page).to have_content(visible_event_group.name)
    expect(page).to have_content(visible_event_1.name)
    expect(page).to have_content(visible_event_2.name)

    expect(page).not_to have_content(concealed_event_group.name)
    expect(page).not_to have_content(concealed_event_1.name)
    expect(page).not_to have_content(concealed_event_2.name)

    expect(page).not_to have_content(outside_event_group.name)
    expect(page).not_to have_content(outside_event_1.name)
    expect(page).not_to have_content(outside_event_2.name)
  end

  scenario 'The user is a non-admin user that did not create the organization and is not a steward of the organization' do
    login_as user, scope: :user

    visit organization_path(organization)

    expect(page).to have_content(organization.name)
    expect(page).to have_content('Courses')
    expect(page).to have_content('Events')
    expect(page).not_to have_content('Stewards')

    expect(page).to have_content(visible_event_group.name)
    expect(page).to have_content(visible_event_1.name)
    expect(page).to have_content(visible_event_2.name)

    expect(page).not_to have_content(concealed_event_group.name)
    expect(page).not_to have_content(concealed_event_1.name)
    expect(page).not_to have_content(concealed_event_2.name)

    expect(page).not_to have_content(outside_event_group.name)
    expect(page).not_to have_content(outside_event_1.name)
    expect(page).not_to have_content(outside_event_2.name)
  end

  scenario 'The user is a non-admin user that created the organization' do
    login_as owner, scope: :user

    visit organization_path(organization)

    expect(page).to have_content(organization.name)
    expect(page).to have_content('Courses')
    expect(page).to have_content('Events')
    expect(page).to have_content('Stewards')

    expect(page).to have_content(visible_event_group.name)
    expect(page).to have_content(visible_event_1.name)
    expect(page).to have_content(visible_event_2.name)

    expect(page).to have_content(concealed_event_group.name)
    expect(page).to have_content(concealed_event_1.name)
    expect(page).to have_content(concealed_event_2.name)

    expect(page).not_to have_content(outside_event_group.name)
    expect(page).not_to have_content(outside_event_1.name)
    expect(page).not_to have_content(outside_event_2.name)
  end

  scenario 'The user is a non-admin user that is a steward of the organization' do
    login_as steward, scope: :user

    visit organization_path(organization)

    expect(page).to have_content(organization.name)
    expect(page).to have_content('Courses')
    expect(page).to have_content('Events')
    expect(page).not_to have_content('Stewards')

    expect(page).to have_content(visible_event_group.name)
    expect(page).to have_content(visible_event_1.name)
    expect(page).to have_content(visible_event_2.name)

    expect(page).to have_content(concealed_event_group.name)
    expect(page).to have_content(concealed_event_1.name)
    expect(page).to have_content(concealed_event_2.name)

    expect(page).not_to have_content(outside_event_group.name)
    expect(page).not_to have_content(outside_event_1.name)
    expect(page).not_to have_content(outside_event_2.name)
  end

  scenario 'The user is an admin user' do
    login_as admin, scope: :user

    visit organization_path(organization)

    expect(page).to have_content(organization.name)
    expect(page).to have_content('Courses')
    expect(page).to have_content('Events')
    expect(page).to have_content('Stewards')

    expect(page).to have_content(visible_event_group.name)
    expect(page).to have_content(visible_event_1.name)
    expect(page).to have_content(visible_event_2.name)

    expect(page).to have_content(concealed_event_group.name)
    expect(page).to have_content(concealed_event_1.name)
    expect(page).to have_content(concealed_event_2.name)

    expect(page).not_to have_content(outside_event_group.name)
    expect(page).not_to have_content(outside_event_1.name)
    expect(page).not_to have_content(outside_event_2.name)
  end

  scenario 'The user is a visitor that clicks the Courses link' do
    visit organization_path(organization)
    click_link 'Courses'

    expect(page).to have_content(visible_event_1.course.name)
    expect(page).to have_content(visible_event_2.course.name)
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
end
