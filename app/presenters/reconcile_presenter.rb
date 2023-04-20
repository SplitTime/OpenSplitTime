# frozen_string_literal: true

class ReconcilePresenter < BasePresenter
  attr_reader :event_group, :view_context
  delegate :available_live?,
           :concealed?,
           :efforts,
           :id,
           :name,
           :organization,
           :scheduled_start_time_local,
           :unreconciled_efforts,
           to: :event_group

  def initialize(event_group, view_context)
    @event_group = event_group
    @view_context = view_context
    @params = view_context.prepared_params
    @current_user = view_context.current_user
    unreconciled_batch.each(&:suggest_close_match)
  end

  def event_group_name
    event_group.name
  end

  def events
    @events ||= event_group.events
  end

  def no_persisted_events?
    @persisted_events ||= events.none?(&:persisted?)
  end

  def status
    available_live? ? "live" : "not_live"
  end

  def unreconciled_batch
    @unreconciled_batch ||= event_group.unreconciled_efforts.includes(split_times: :split).order(:last_name).limit(20)
  end

  private

  attr_reader :params, :current_user
end
