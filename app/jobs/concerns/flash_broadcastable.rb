module FlashBroadcastable
  extend ActiveSupport::Concern

  private

  def broadcast_flash(streamable, message:, level: :success)
    Turbo::StreamsChannel.broadcast_replace_to(
      streamable,
      target: "flash",
      partial: "layouts/flash",
      locals: { flash: { level => message } }
    )
  end
end
