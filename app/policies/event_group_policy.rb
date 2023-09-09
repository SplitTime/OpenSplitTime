# frozen_string_literal: true

class EventGroupPolicy < ApplicationPolicy
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

  attr_reader :event_group

  def post_initialize(event_group)
    @event_group = event_group
  end

  def setup?
    user.authorized_to_edit?(event_group)
  end

  def entrants?
    setup?
  end

  def setup_summary?
    setup?
  end

  def raw_times?
    user.authorized_to_edit?(event_group)
  end

  def split_raw_times?
    user.authorized_to_edit?(event_group)
  end

  def reconcile?
    setup?
  end

  def auto_reconcile?
    setup?
  end

  def associate_people?
    setup?
  end

  def create_people?
    setup?
  end

  def link_lotteries?
    setup?
  end

  def connections?
    setup?
  end

  def connect_service?
    setup?
  end

  def assign_bibs?
    setup?
  end

  def auto_assign_bibs?
    setup?
  end

  def update_bibs?
    setup?
  end

  def assign_entrant_photos?
    setup?
  end

  def manage_entrant_photos?
    setup?
  end

  def update_entrant_photos?
    setup?
  end

  def delete_entrant_photos?
    setup?
  end

  def delete_photos_from_entrants?
    setup?
  end

  def manage_start_times?
    setup?
  end

  def manage_start_times_edit_actual?
    setup?
  end

  def roster?
    user.authorized_to_edit?(event_group)
  end

  def stats?
    roster?
  end

  def finish_line?
    roster?
  end

  def delete_all_efforts?
    user.authorized_fully?(event_group)
  end

  def delete_all_times?
    user.authorized_fully?(event_group)
  end

  def delete_duplicate_raw_times?
    user.authorized_to_edit?(event_group)
  end

  def set_data_status?
    roster?
  end

  def start_efforts_form?
    start_efforts?
  end

  def start_efforts?
    roster?
  end

  def update_all_efforts?
    user.authorized_to_edit?(event_group)
  end

  def export_raw_times?
    user.authorized_to_edit?(event_group)
  end

  def live_entry?
    user.authorized_to_edit?(event_group)
  end

  def trigger_raw_times_push?
    live_entry?
  end

  def import?
    setup?
  end

  def pull_raw_times?
    live_entry?
  end

  def enrich_raw_time_row?
    user.present?
  end

  def submit_raw_time_rows?
    user.authorized_to_edit?(event_group)
  end

  def pull_time_record_rows?
    user.authorized_to_edit?(event_group)
  end

  def not_expected?
    user.authorized_to_edit?(event_group)
  end

  def webhooks?
    user.present?
  end
end
