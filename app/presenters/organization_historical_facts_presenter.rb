class OrganizationHistoricalFactsPresenter < OrganizationPresenter
  include PagyPresenter

  DEFAULT_ORDER = { last_name: :asc, first_name: :asc, state_code: :asc, year: :asc, kind: :asc }

  attr_reader :request

  def initialize(organization, view_context)
    super
    @request = view_context.request
  end

  # @return [Boolean]
  def all_reconciled?
    historical_facts.unreconciled.blank?
  end

  def historical_facts
    organization.historical_facts
  end

  def historical_facts_count
    historical_facts.size
  end

  def filtered_historical_facts
    return @filtered_historical_facts if defined?(@filtered_historical_facts)

    @pagy, @filtered_historical_facts = pagy_from_scope(
      filtered_historical_facts_unpaginated,
      limit: per_page,
      page: page
    )
    @filtered_historical_facts
  end

  def filtered_historical_facts_unpaginated
    historical_facts
      .where(filter_hash)
      .by_kind(param_kinds)
      .by_reconciled(param_reconciled)
      .search(search_text)
      .order(sort_hash.presence || DEFAULT_ORDER)
  end

  def filtered_historical_facts_count
    @filtered_historical_facts_count ||= filtered_historical_facts.size
  end

  def filtered_historical_facts_unpaginated_count
    pagy.count
  end

  def next_page_url
    view_context.url_for(request.params.merge(page: pagy.next)) if pagy.next
  end

  def kind
    params.filter[:kind] || "All Kinds"
  end

  private

  def pagy
    filtered_historical_facts
    @pagy
  end

  # @return [Array<String>]
  def param_kinds
    params[:kind].presence || []
  end

  # @return [Boolean, nil]
  def param_reconciled
    params[:reconciled].present? ? params[:reconciled].to_boolean : nil
  end
end
