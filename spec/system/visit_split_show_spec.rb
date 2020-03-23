# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'visit a split show page' do
  let(:user) { users(:third_user) }
  let(:owner) { users(:fourth_user) }
  let(:steward) { users(:fifth_user) }
  let(:admin) { users(:admin_user) }

  before do
    organization.update(created_by: owner.id)
    organization.stewards << steward
  end

  let(:event) { events(:hardrock_2016) }
  let(:event_group) { event.event_group}
  let(:organization) { event_group.organization }

  let(:course) { event.course }

  let(:start_split) { course.ordered_splits.first }
  let(:intermediate_split) { course.ordered_splits.second }
  let(:finish_split) { course.ordered_splits.last }

  context 'When the split is a start split' do
    let(:split) { start_split }

    scenario 'The user is a visitor' do
      visit split_path(split)
      
      verify_page_content
      verify_admin_links_absent
    end

    scenario 'The user is not the owner and is not a steward' do
      login_as user, scope: :user
      visit split_path(split)
      
      verify_page_content
      verify_admin_links_absent
    end

    scenario 'The user is the owner' do
      login_as owner, scope: :user
      visit split_path(split)
      
      verify_page_content
      verify_admin_links_present
    end

    scenario 'The user is a steward of the organization related to the event' do
      login_as steward, scope: :user
      visit split_path(split)
      
      verify_page_content
      verify_admin_links_present
    end

    scenario 'The user is an admin' do
      login_as admin, scope: :user
      visit split_path(split)
      
      verify_page_content
      verify_admin_links_present
    end
  end

  context 'When the split is intermediate' do
    let(:split) { intermediate_split }

    scenario 'The user is a visitor' do
      visit split_path(split)
      
      verify_page_content
      verify_admin_links_absent
    end

    scenario 'The user is not the owner and is not a steward' do
      login_as user, scope: :user
      visit split_path(split)
      
      verify_page_content
      verify_admin_links_absent
    end

    scenario 'The user is the owner' do
      login_as owner, scope: :user
      visit split_path(split)
      
      verify_page_content
      verify_admin_links_present
    end

    scenario 'The user is a steward of the organization related to the event' do
      login_as steward, scope: :user
      visit split_path(split)
      
      verify_page_content
      verify_admin_links_present
    end

    scenario 'The user is an admin' do
      login_as admin, scope: :user
      visit split_path(split)

      verify_page_content
      verify_admin_links_present
    end
  end

  context 'When the split is a finish split' do
    let(:split) { finish_split }

    scenario 'The user is a visitor' do
      visit split_path(split)
      
      verify_page_content
      verify_admin_links_absent
    end

    scenario 'The user is not the owner and is not a steward' do
      login_as user, scope: :user
      visit split_path(split)
      
      verify_page_content
      verify_admin_links_absent
    end

    scenario 'The user is the owner' do
      login_as owner, scope: :user
      visit split_path(split)

      verify_page_content
      verify_admin_links_present
    end

    scenario 'The user is a steward of the organization related to the event' do
      login_as steward, scope: :user
      visit split_path(split)

      verify_page_content
      verify_admin_links_present
    end

    scenario 'The user is an admin' do
      login_as admin, scope: :user
      visit split_path(split)

      verify_page_content
      verify_admin_links_present
    end
  end

  context 'when the course is hidden' do
    let(:split) { intermediate_split }
    before { course.update(concealed: true) }

    scenario 'The user is a visitor' do
      verify_page_not_found
    end

    scenario 'The user is not the owner and is not a steward' do
      login_as user, scope: :user
      verify_page_not_found
    end

    scenario 'The user is the owner' do
      login_as owner, scope: :user
      visit split_path(split)

      verify_page_content
      verify_admin_links_present
    end

    scenario 'The user is a steward of the organization related to the event' do
      login_as steward, scope: :user
      visit split_path(split)

      verify_page_content
      verify_admin_links_present
    end

    scenario 'The user is an admin' do
      login_as admin, scope: :user
      visit split_path(split)

      verify_page_content
      verify_admin_links_present
    end
  end

  def verify_page_content
    expect(page).to have_content(split.base_name)
    expect(page).to have_content(course.name)
  end

  def verify_admin_links_absent
    expect(page).not_to have_content('Edit Split')
  end

  def verify_admin_links_present
    expect(page).to have_link('Edit Split', href: edit_split_path(split))
  end

  def verify_page_not_found
    expect { visit split_path(split) }.to raise_error ::ActiveRecord::RecordNotFound
  end
end
