module FlashBroadcastable
  extend ActiveSupport::Concern

  private

  def broadcast_flash(streamable, message:, level: :success)
    Turbo::StreamsChannel.broadcast_replace_to(
      streamable,
      target: "flash",
      partial: "layouts/broadcast_flash",
      locals: { level: level, message: message }
    )
  end
end
