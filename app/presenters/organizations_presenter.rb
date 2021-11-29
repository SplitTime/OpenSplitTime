# frozen_string_literal: true

class OrganizationsPresenter < BasePresenter
  attr_reader :organizations

  def initialize(view_context)
    @view_context = view_context
  end

  def next_page_url
    view_context.url_for(request.params.merge(page: page + 1)) if records_from_context_count == per_page
  end

  def page
    params[:page]&.to_i || 1
  end

  def per_page
    params[:per_page]&.to_i || 25
  end

  def records_from_context
    @records_from_context ||= OrganizationPolicy::Scope.new(current_user, Organization)
                                                       .viewable
                                                       .order(:name)
                                                       .with_visible_event_count
                                                       .paginate(page: page, per_page: per_page)
  end

  private

  attr_reader :view_context
  delegate :current_user, :params, :request, to: :view_context

  def records_from_context_count
    @records_from_context_count ||= records_from_context.size
  end
end
