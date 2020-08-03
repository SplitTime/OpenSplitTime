# frozen_string_literal: true

class EventSeriesPolicy < ApplicationPolicy
  class Scope < ApplicationPolicy::Scope
    def post_initialize
    end

    def authorized_to_edit_records
      scope.delegated_to(user)
    end

    def authorized_to_view_records
      scope.visible_or_delegated_to(user)
    end
  end

  attr_reader :event_series

  def post_initialize(event_series)
    @event_series = event_series
  end

  def new?
    event_series.organization && user.authorized_to_edit?(event_series.organization)
  end

  def create?
    event_series.organization && user.authorized_to_edit?(event_series.organization)
  end
end
