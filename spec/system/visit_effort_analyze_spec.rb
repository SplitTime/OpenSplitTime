# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'visit an effort analyze page' do
  let(:user) { users(:third_user) }
  let(:owner) { users(:fourth_user) }
  let(:steward) { users(:fifth_user) }
  let(:admin) { users(:admin_user) }

  before do
    organization.update(created_by: owner.id)
    organization.stewards << steward
  end

  let(:event) { events(:hardrock_2014) }
  let(:organization) { event.organization }

  let(:completed_effort) { efforts(:hardrock_2014_finished_first) }
  let(:in_progress_effort) { efforts(:hardrock_2014_progress_sherman) }
  let(:unstarted_effort) { efforts(:hardrock_2014_not_started) }

  context 'When the effort is finished' do
    let(:effort) { completed_effort }

    scenario 'For a visitor and each type of user' do
      [nil, user, owner, steward, admin].each do |role|
        login_as role if role
        visit analyze_effort_path(effort)
        verify_page_header
        verify_split_names
      end
    end
  end

  context 'when the effort is partially finished' do
    let(:effort) { in_progress_effort }

    scenario 'For a visitor and each type of user' do
      [nil, user, owner, steward, admin].each do |role|
        login_as role if role
        visit analyze_effort_path(effort)
        verify_page_header
        verify_split_names
      end
    end
  end

  context 'when the effort is not started' do
    let(:effort) { unstarted_effort }

    scenario 'For a visitor and each type of user' do
      [nil, user, owner, steward, admin].each do |role|
        login_as role if role
        visit analyze_effort_path(effort)
        verify_page_header
        expect(page).to have_text('Cannot analyze an unstarted effort')
      end
    end
  end

  def verify_page_header
    expect(page).to have_content(effort.full_name)
    expect(page).to have_link('Split times', href: effort_path(effort))
    unless effort == unstarted_effort
      expect(page).to have_link('Places + peers', href: place_effort_path(effort))
    end
  end

  def verify_split_names
    event.splits.each { |split| expect(page).to have_content(split.base_name) }
  end
end
