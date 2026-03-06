# frozen_string_literal: true

# Pagy pagination support for presenters
# Include this module to add pagy pagination methods to presenters
module PagyPresenter
  include Pagy::Method

  # Paginate a scope using Pagy
  #
  # @param scope [ActiveRecord::Relation] The scope to paginate
  # @param limit [Integer] Items per page (default: 25)
  # @param page [Integer] Current page number
  # @param count [Integer, nil] Total count (optional, will be calculated if not provided)
  # @return [Array<Pagy, ActiveRecord::Relation>]
  def pagy_from_scope(scope, limit: 25, page: 1, count: nil)
    count ||= scope.reorder(nil).count(:all)
    count = count.values.sum if count.is_a?(Hash)

    # Pass explicit page/limit via request hash rather than relying on view_context.request.params
    # This keeps the method parameters explicit and makes testing simpler (no need to mock full request)
    request_hash = { params: { 'page' => page.to_s, 'limit' => limit.to_s } }

    pagy(:offset, scope, limit: limit, count: count, request: request_hash)
  end

  # Paginate without running a COUNT query.
  # Fetches limit + 1 to determine if a next page exists.
  # Returns [Pagy::Countless, Array].
  def pagy_countless_from_scope(scope, limit: 25, page: 1)
    # Pass explicit page/limit via request hash (same reasoning as pagy_from_scope)
    request_hash = { params: { 'page' => page.to_s, 'limit' => limit.to_s } }

    # Pagy::Countless only supports :empty_page or :exception overflow options
    # (not :last_page which is the global default)
    pagy(:countless, scope, limit: limit, overflow: :empty_page, request: request_hash)
  end
end
