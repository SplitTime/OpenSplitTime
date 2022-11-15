# frozen_string_literal: true

class EventGroupsChannel < ApplicationCable::Channel
  def subscribed
    event_group = EventGroup.find(params[:id])

    if current_user&.authorized_to_edit?(event_group)
      stream_for event_group.id
    else
      reject
    end
  end

  def unsubscribed
    stop_all_streams
  end
end
