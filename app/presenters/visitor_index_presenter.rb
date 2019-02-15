# frozen_string_literal: true

class VisitorIndexPresenter < BasePresenter
  def initialize(current_user)
    @current_user = current_user
  end

  def recent_event_groups(number)
    EventGroup.visible.includes(events: :efforts).reject { |eg| eg.effort_count.zero? }.sort_by(&:start_time).reverse.first(number)
  end

  def upcoming_courses(number)
    Course.where('next_start_time > ?', Time.current).order(:next_start_time).limit(number)
  end

  def recent_user_efforts(number)
    user_efforts.first(number)
  end

  def user_efforts
    return nil unless avatar
    @user_efforts ||= avatar.efforts.includes(:split_times).sort_by(&:calculated_start_time).reverse
  end

  private

  def avatar
    current_user.avatar
  end

  attr_reader :current_user
end
