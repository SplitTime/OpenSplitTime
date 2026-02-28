# frozen_string_literal: true

class EventGroupsCollectionPresenter < BasePresenter
  DEFAULT_PER_PAGE = 25

  attr_reader :event_groups

  def initialize(event_groups, view_context)
    @event_groups = event_groups
    @view_context = view_context
    @params = view_context.prepared_params
  end

  def show_visibility_columns?
    current_user&.admin? || current_user&.stewardships.present?
  end

  def next_page_url
    view_context.url_for(request.params.merge(page: page + 1)) if event_groups.size == DEFAULT_PER_PAGE
  end

  private

  attr_reader :params, :view_context

  delegate :current_user, :request, to: :view_context, private: true
end
