# frozen_string_literal: true

class EventPolicy < ApplicationPolicy
  class Scope < ApplicationPolicy::Scope
    def post_initialize
    end

    def delegated_records
      if user
        scope.joins(event_group: {organization: :stewardships})
            .includes(event_group: {organization: :stewardships}).delegated(user.id)
      else
        scope.none
      end
    end
  end

  attr_reader :event

  def post_initialize(event)
    @event = event
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

  def delete_all_efforts?
    user.authorized_fully?(event)
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

  def export_finishers?
    user.authorized_to_edit?(event)
  end

  def export_to_ultrasignup?
    user.authorized_to_edit?(event)
  end

  def aid_station_detail?
    user.authorized_to_edit?(event)
  end

  # Policies for live namespace

  def progress_report?
    user.authorized_to_edit?(event)
  end

  def aid_station_report?
    user.authorized_to_edit?(event)
  end

  # Policies for staging namespace

  def get_countries?
    user.present?
  end

  def get_time_zones?
    user.present?
  end

  def get_locations?
    user.authorized_to_edit?(event)
  end

  def event_staging_app?
    user.authorized_to_edit?(event)
  end

  def post_event_course_org?
    user.authorized_to_edit?(event)
  end

  def update_event_visibility?
    user.authorized_to_edit?(event)
  end

  def new_staging?
    user.present?
  end
end
