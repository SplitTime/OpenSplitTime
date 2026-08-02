class StartEffortsJob < ApplicationJob
  include FlashBroadcastable

  queue_as :default

  def perform(task, effort_ids:, start_time:, current_user: nil)
    set_current_user(current_user: current_user)
    event_group = task.parent

    efforts = event_group.efforts.where(id: effort_ids).includes(:event, split_times: :split)
    start_response = ::Interactors::StartEfforts.perform!(efforts: efforts, start_time: start_time,
                                                          broadcast_rows: false)

    status_efforts = event_group.efforts.where(id: effort_ids).includes(split_times: :split)
    set_response = ::Interactors::UpdateEffortsStatus.perform!(status_efforts)

    response = start_response.merge(set_response)
    if response.successful?
      task.finished!
      broadcast_remaining_rows(effort_ids, set_response)
      broadcast_flash(event_group, message: response.message)
    else
      task.update(status: :failed, error_message: response.message_with_error_report)
      broadcast_flash(event_group, message: response.message_with_error_report, level: :danger)
    end
    broadcast_start_button(event_group)
  rescue StandardError => e
    task.update(status: :failed, error_message: e.message)
    broadcast_flash(task.parent, message: "Could not start entrants: #{e.message}", level: :danger)
    broadcast_start_button(task.parent)
    raise
  end

  private

  # UpdateEffortsStatus broadcasts its changed efforts; rows whose start
  # changed but whose status did not still need a broadcast
  def broadcast_remaining_rows(effort_ids, set_response)
    broadcast_ids = set_response.resources.grep(::Effort).to_set(&:id)
    remaining_ids = effort_ids.reject { |id| broadcast_ids.include?(id) }
    return if remaining_ids.empty?

    ::Effort.where(id: remaining_ids).includes(event: :event_group).find_each(&:broadcast_update)
  end

  def broadcast_start_button(event_group)
    ::Turbo::StreamsChannel.broadcast_replace_to(
      event_group,
      target: ::ActionView::RecordIdentifier.dom_id(event_group, :start_ready_efforts_button),
      partial: "event_groups/start_ready_efforts_button",
      locals: { presenter: ::EventGroupStartPresenter.new(event_group) },
    )
  end
end
