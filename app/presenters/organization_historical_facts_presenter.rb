# frozen_string_literal: true

class OrganizationHistoricalFactsPresenter < OrganizationPresenter
  DEFAULT_ORDER = { last_name: :asc, first_name: :asc, state_code: :asc, year: :asc }

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

    @filtered_historical_facts = historical_facts
      .where(filter_hash)
      .by_kind(param_kinds)
      .by_reconciled(param_reconciled)
      .search(search_text)
      .order(sort_hash.presence || DEFAULT_ORDER)
      .paginate(page: page, per_page: per_page)
  end

  def filtered_historical_facts_count
    filtered_historical_facts.size
  end

  def filtered_historical_facts_unpaginated_count
    filtered_historical_facts.total_entries
  end

  def next_page_url
    view_context.url_for(request.params.merge(page: page + 1)) if filtered_historical_facts_count == per_page
  end

  def kind
    params.filter[:kind] || "All Kinds"
  end

  private

  # @return [Array<String>]
  def param_kinds
    params[:kind].presence || []
  end

  # @return [Boolean, nil]
  def param_reconciled
    params[:reconciled].present? ? params[:reconciled].to_boolean : nil
  end
end
