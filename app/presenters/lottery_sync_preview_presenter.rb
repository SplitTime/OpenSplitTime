# frozen_string_literal: true

class LotterySyncPreviewPresenter
  def initialize(event, view_context)
    @event = event
    @view_context = view_context
  end

  attr_reader :event

  def created_efforts
    preview_response.resources[:created_efforts]
  end

  def deleted_efforts
    preview_response.resources[:deleted_efforts]
  end

  def updated_efforts
    preview_response.resources[:updated_efforts]
  end

  private

  attr_reader :view_context

  def preview_response
    @preview_response ||= ::Interactors::SyncLotteryEntrants.preview(event)
  end
end
