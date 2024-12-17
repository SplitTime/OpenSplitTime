# frozen_string_literal: true

class MyStuffPresenter < BasePresenter
  attr_reader :current_user

  delegate :full_name, to: :current_user

  def initialize(current_user)
    @current_user = current_user
  end

  def recent_event_groups(number)
    event_groups.sort_by { |eg| eg.scheduled_start_time || Time.current }.reverse.first(number)
  end

  def event_groups
    EventGroup.includes(events: :efforts).where(organization: organizations)
  end

  def recent_event_series(number)
    event_series.sort_by(&:scheduled_start_time).reverse.first(number)
  end

  def event_series
    EventSeries.includes(:events).where(organization: organizations)
  end

  def drawn_lottery_entrants
    LotteryEntrant.belonging_to_user(current_user)
      .drawn
      .includes(:service_detail, division: { lottery: :organization })
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
    return Effort.none unless avatar

    @user_efforts ||= avatar.efforts.joins(:event).includes(event: :event_group).order("events.scheduled_start_time desc")
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
