module FlashBroadcastable
  extend ActiveSupport::Concern

  included do
    include Rails.application.routes.url_helpers
  end

  private

  def broadcast_flash(streamable, message:, level: :success, action_url: nil, action_text: "Refresh")
    Turbo::StreamsChannel.broadcast_replace_to(
      streamable,
      target: "flash",
      partial: "layouts/broadcast_flash",
      locals: { level: level, message: message, action_url: action_url, action_text: action_text }
    )
  end
end
