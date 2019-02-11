# frozen_string_literal: true

class VisitorIndexPresenter < BasePresenter
  def initialize
  end

  def recent_event_groups(number)
    EventGroup.visible.includes(:events).sort_by(&:start_time).reverse.first(number)
  end

  def upcoming_courses(number)
    Course.where('next_start_time > ?', Time.current).order(:next_start_time).limit(number)
  end
end
