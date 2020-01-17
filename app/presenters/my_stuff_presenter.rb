# frozen_string_literal: true

class MyStuffPresenter < BasePresenter
  attr_reader :current_user
  delegate :full_name, to: :current_user

  def initialize(current_user)
    @current_user = current_user
  end

  def recent_event_groups(number)
    event_groups.sort_by { |eg| eg.start_time || Time.current }.reverse.first(number)
  end

  def event_groups
    EventGroup.includes(events: :efforts).where(organization: organizations)
  end

  def recent_event_series(number)
    event_series.sort_by(&:start_time).reverse.first(number)
  end

  def event_series
    EventSeries.includes(:events).where(organization: organizations)
  end

  def organizations
    owned_organizations | steward_organizations
  end

  def owned_organizations
    Organization.where(created_by: current_user.id).order(:name)
  end

  def steward_organizations
    current_user.organizations.where.not(created_by: current_user.id).order(:name)
  end

  def recent_user_efforts(number)
    user_efforts.first(number)
  end

  def user_efforts
    return nil unless avatar
    @user_efforts ||= avatar.efforts.includes(:split_times).sort_by(&:calculated_start_time).reverse
  end

  def interests
    current_user.interests.distinct.order(:last_name)
  end

  def watch_efforts
    current_user.watch_efforts.includes(:event).distinct.order(:last_name)
  end

  private

  def avatar
    current_user.avatar
  end
end
