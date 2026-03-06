# frozen_string_literal: true

# Pagy pagination support for presenters
# Include this module to add pagy pagination methods to presenters
#
# Both methods require explicit scope and request arguments.
# In production presenters, pass request from view_context.
# In tests, pass a request hash with params.
module PagyPresenter
  include Pagy::Method

  # Paginate a scope using Pagy
  #
  # @param scope [ActiveRecord::Relation] The scope to paginate
  # @param request [ActionDispatch::Request, Hash] Request object or hash with :params
  # @param count [Integer, nil] Total count (optional, will be calculated if not provided)
  # @param options [Hash] Additional pagy options
  # @return [Array<Pagy, ActiveRecord::Relation>]
  def pagy_from_scope(scope, request, count: nil, **options)
    count ||= scope.reorder(nil).count(:all)
    count = count.values.sum if count.is_a?(Hash)

    pagy(:offset, scope, count: count, request: request, **options)
  end

  # Paginate without running a COUNT query.
  # Fetches limit + 1 to determine if a next page exists.
  # Returns [Pagy::Countless, Array].
  #
  # @param scope [ActiveRecord::Relation] The scope to paginate
  # @param request [ActionDispatch::Request, Hash] Request object or hash with :params
  # @param options [Hash] Additional pagy options
  # @return [Array<Pagy::Countless, ActiveRecord::Relation>]
  def pagy_countless_from_scope(scope, request, **options)
    # Pagy::Countless only supports :empty_page or :exception overflow options
    # (not :last_page which is the global default)
    pagy(:countless, scope, request: request, overflow: :empty_page, **options)
  end
end
