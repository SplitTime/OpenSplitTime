class VisitorIndexPresenter < BasePresenter
  def initialize(current_user)
    @current_user = current_user
  end

  def recent_event_groups(number)
    EventGroup.having_efforts.visible.by_group_start_time.limit(number)
  end

  def upcoming_courses(number)
    Course.where("next_start_time > ?", Time.current).order(:next_start_time).limit(number)
  end

  private

  attr_reader :current_user

  def avatar
    @avatar ||= current_user.avatar
  end
end
