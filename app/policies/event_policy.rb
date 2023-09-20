# frozen_string_literal: true

class EventPolicy < ApplicationPolicy
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

  attr_reader :event

  def post_initialize(event)
    @event = event
  end

  def setup_course?
    user.authorized_fully?(event)
  end

  def new_course_gpx?
    setup_course?
  end

  def attach_course_gpx?
    setup_course?
  end

  def remove_course_gpx?
    setup_course?
  end

  def spread?
    user.present?
  end

  def summary?
    user.authorized_to_edit?(event)
  end

  def import?
    user.authorized_to_edit?(event)
  end

  def set_stops?
    user.authorized_to_edit?(event)
  end

  def edit_start_time?
    user.admin?
  end

  def update_start_time?
    user.admin?
  end

  def reassign?
    user.authorized_fully?(event)
  end

  def export?
    user.authorized_to_edit?(event)
  end

  def aid_station_detail?
    user.authorized_to_edit?(event)
  end

  def preview_sync?
    user.authorized_to_edit?(event)
  end

  def sync_entrants?
    preview_sync?
  end

  # Policies for live namespace

  def progress_report?
    user.authorized_to_edit?(event)
  end

  def aid_station_report?
    user.authorized_to_edit?(event)
  end
end
