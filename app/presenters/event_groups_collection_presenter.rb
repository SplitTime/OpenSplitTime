# frozen_string_literal: true

class EventGroupsCollectionPresenter < BasePresenter
  attr_reader :event_groups

  def initialize(event_groups_scope, view_context)
    @event_groups_scope = event_groups_scope
    @view_context = view_context
    @params = view_context.prepared_params
  end

  def event_groups
    @event_groups ||= event_groups_scope.paginate(page: page, per_page: per_page)
  end

  def event_groups_count
    @event_groups_count ||= event_groups.size
  end

  def show_visibility_columns?
    current_user&.admin? || current_user&.stewardships.present?
  end

  def next_page_url
    view_context.url_for(request.params.merge(page: page + 1)) if event_groups_count == per_page
  end

  private

  attr_reader :event_groups_scope, :params, :view_context

  delegate :current_user, :request, to: :view_context, private: true
end
