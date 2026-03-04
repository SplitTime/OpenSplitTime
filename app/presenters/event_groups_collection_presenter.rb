# frozen_string_literal: true

class EventGroupsCollectionPresenter < BasePresenter
  include PagyPresenter

  attr_reader :event_groups, :pagy

  def initialize(event_groups_scope, view_context)
    @event_groups_scope = event_groups_scope
    @view_context = view_context
    @params = view_context.prepared_params
  end

  def event_groups
    return @event_groups if defined?(@event_groups)

    @pagy, @event_groups = pagy_from_scope(event_groups_scope, limit: per_page, page: page)
    @event_groups
  end

  def event_groups_count
    @event_groups_count ||= event_groups.size
  end

  def show_visibility_columns?
    current_user&.admin? || current_user&.stewardships.present?
  end

  def next_page_url
    event_groups
    view_context.url_for(request.params.merge(page: pagy.next)) if pagy.next
  end

  private

  attr_reader :event_groups_scope, :params, :view_context

  delegate :current_user, :request, to: :view_context, private: true
end
