# frozen_string_literal: true

class EventSyncPreviewPresenter
  def initialize(event, previewer, view_context)
    @event = event
    @previewer = previewer
    @view_context = view_context
  end

  attr_reader :event

  def syncable?
    created_efforts.present? || deleted_efforts.present? || updated_efforts.present?
  end

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

  attr_reader :previewer, :view_context
  delegate :current_user, to: :view_context, private: true

  def preview_response
    @preview_response ||= previewer.preview(event, current_user)
  end
end