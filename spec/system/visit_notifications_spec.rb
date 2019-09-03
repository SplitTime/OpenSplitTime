# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'visit an event group notifications page' do
  let(:user) { users(:third_user) }
  let(:owner) { users(:fourth_user) }
  let(:steward) { users(:fifth_user) }
  let(:admin) { users(:admin_user) }
  let(:organization) { event_group.organization }

  before do
    organization.update(created_by: owner.id)
    organization.stewards << steward
  end

  context 'The event group has notifications and subscriptions' do
    let(:event_group) { event_groups(:rufa_2017) }
    let(:total_notifications_count) { Notification.where(effort: event_group.efforts).map(&:follower_ids).flatten.size }
    let(:total_notified_entrants_count) { event_group.efforts.joins(:notifications).where.not(notifications: {follower_ids: []}).group(:effort_id).count.keys.size }
    let(:total_subscriptions_count) { Subscription.where(subscribable_type: 'Effort', subscribable_id: efforts).count }

    scenario 'The user is an admin' do
      login_as admin, scope: :user
      visit notifications_event_group_path(event_group)
      verify_links_present
      verify_counts_text
    end

    scenario 'The user is the owner of the organization' do
      login_as owner, scope: :user
      visit notifications_event_group_path(event_group)
      verify_links_present
      verify_counts_text
    end

    scenario 'The user is a steward of the event_group' do
      login_as steward, scope: :user
      visit notifications_event_group_path(event_group)
      verify_links_present
      verify_counts_text
    end
  end

  context 'The event group has no subscriptions or notifications' do
    let(:event_group) { event_groups(:sum) }

    scenario 'The user is the owner of the organization' do
      login_as owner, scope: :user
      visit notifications_event_group_path(event_group)
      verify_links_present
      verify_no_notices_text
      verify_no_subs_text
    end
  end

  def verify_counts_text
    expect(page).to have_content("Tracking #{total_subscriptions_count} subscriptions")
    expect(page).to have_content("Sent #{total_notifications_count} notifications relating to #{total_notified_entrants_count} entrants")
  end

  def verify_links_present
    verify_content_present(event_group)
  end

  def verify_no_notices_text
    expect(page).to have_content('No notifications have been sent for this event group')
  end
  def verify_no_subs_text
    expect(page).to have_content('No subscriptions exist for this event group')
  end
end
