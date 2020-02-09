# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'visit an effort audit page' do
  let(:user) { users(:third_user) }
  let(:owner) { users(:fourth_user) }
  let(:steward) { users(:fifth_user) }
  let(:admin) { users(:admin_user) }

  before do
    organization.update(created_by: owner.id)
    organization.stewards << steward
  end

  let(:effort) { efforts(:sum_100k_drop_anvil) }
  let(:event) { effort.event }
  let(:event_group) { event.event_group }
  let(:organization) { event_group.organization }

  let(:time_point) { TimePoint.new(lap, split_id, bitkey) }
  let(:lap) { 1 }
  let(:split_id) { split.id }
  let(:split) { splits(:sum_100k_course_rolling_pass_aid2) }
  let(:bitkey) { SubSplit::OUT_BITKEY }
  let(:split_time) { SplitTime.find_by(effort: effort, lap: lap, split: split, sub_split_bitkey: bitkey) }

  let(:matched_raw_time) { split_time.raw_times.first }
  let(:unmatched_raw_time) { raw_times(:raw_time_87) }

  shared_examples 'authorized user visits and clicks links' do
    scenario 'The user visits the page' do
      visit audit_effort_path(effort)
      verify_links_present
    end

    scenario 'The user matches a raw time' do
      visit audit_effort_path(effort)

      expect(page).not_to have_link(id: "unmatch-raw-time-#{unmatched_raw_time.id}")
      expect(page).to have_link(id: "unmatch-raw-time-#{matched_raw_time.id}")
      expect(split_time.raw_times).not_to include(unmatched_raw_time)
      expect(split_time.raw_times).to include(matched_raw_time)

      click_link(id: "match-raw-time-#{unmatched_raw_time.id}")
      split_time.reload

      expect(page).to have_link(id: "unmatch-raw-time-#{unmatched_raw_time.id}")
      expect(page).to have_link(id: "unmatch-raw-time-#{matched_raw_time.id}")
      expect(split_time.raw_times).to include(unmatched_raw_time)
      expect(split_time.raw_times).to include(matched_raw_time)
    end

    scenario 'The user unmatches a raw time' do
      visit audit_effort_path(effort)

      expect(page).not_to have_link(id: "unmatch-raw-time-#{unmatched_raw_time.id}")
      expect(page).to have_link(id: "unmatch-raw-time-#{matched_raw_time.id}")
      expect(split_time.raw_times).not_to include(unmatched_raw_time)
      expect(split_time.raw_times).to include(matched_raw_time)

      click_link(id: "unmatch-raw-time-#{matched_raw_time.id}")
      split_time.reload

      expect(page).not_to have_link(id: "unmatch-raw-time-#{unmatched_raw_time.id}")
      expect(page).not_to have_link(id: "unmatch-raw-time-#{matched_raw_time.id}")
      expect(split_time.raw_times).not_to include(unmatched_raw_time)
      expect(split_time.raw_times).not_to include(matched_raw_time)
    end
  end

  context 'The user is an admin' do
    before { login_as admin, scope: :user }
    include_examples 'authorized user visits and clicks links'
  end

  context 'The user is an owner' do
    before { login_as owner, scope: :user }
    include_examples 'authorized user visits and clicks links'
  end

  context 'The user is a steward' do
    before { login_as steward, scope: :user }
    include_examples 'authorized user visits and clicks links'
  end

  context 'The user is not an owner or steward' do
    before { login_as user, scope: :user }
    scenario 'The user visits the page' do
      visit audit_effort_path(effort)
      verify_redirect_to_root
    end
  end

  context 'The user is a visitor' do
    scenario 'The user visits the page' do
      visit audit_effort_path(effort)
      verify_redirect_to_root
    end
  end

  def verify_links_present
    verify_content_present(effort)
    verify_split_raw_times_link_present
  end

  def verify_split_raw_times_link_present
    path = split_raw_times_event_group_path(event_group,
                                            parameterized_split_name: split.parameterized_base_name,
                                            sub_split_kind: SubSplit.kind(bitkey).downcase)
    expect(page).to have_link(split.name(bitkey), href: path)
  end

  def verify_redirect_to_root
    expect(current_path).to eq(root_path)
  end
end
