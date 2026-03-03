class OrganizationsPresenter < BasePresenter
  include PagyPresenter

  attr_reader :organizations, :pagy

  def initialize(view_context)
    @view_context = view_context
  end

  def next_page_url
    view_context.url_for(request.params.merge(page: pagy.next)) if pagy.next
  end

  def records_from_context
    return @records_from_context if defined?(@records_from_context)

    base_scope = OrganizationPolicy::Scope.new(current_user, Organization).viewable
    scope = base_scope
        .order(:name)
        .with_visible_event_count

    # Count on base scope (without grouping) to get total number of organizations
    total_count = base_scope.count

    @pagy, @records_from_context = pagy_from_scope(scope, items: per_page, page: page, count: total_count)
    @records_from_context
  end

  private

  attr_reader :view_context
  delegate :current_user, :params, :request, to: :view_context, private: true

  def records_from_context_count
    @records_from_context_count ||= pagy.count
  end
end
