# frozen_string_literal: true

# Pagy pagination support for presenters
# Include this module to add pagy pagination methods to presenters
#
# In production, expects the including class to delegate 'request' to view_context.
# In tests, pass explicit limit:/page: options or a request: hash.
module PagyPresenter
  include Pagy::Method

  # Paginate a scope using Pagy
  #
  # @param scope [ActiveRecord::Relation] The scope to paginate
  # @param count [Integer, nil] Total count (optional, will be calculated if not provided)
  # @param limit [Integer] Items per page (for tests or explicit override)
  # @param page [Integer] Page number (for tests or explicit override)
  # @param options [Hash] Additional pagy options
  # @return [Array<Pagy, ActiveRecord::Relation>]
  def pagy_from_scope(scope, count: nil, limit: nil, page: nil, **options)
    count ||= scope.reorder(nil).count(:all)
    count = count.values.sum if count.is_a?(Hash)

    # If limit/page are explicitly provided (tests), pass them via request hash
    # Otherwise, pagy will use self.request (delegated to view_context in production)
    if limit || page
      request_hash = { params: {} }
      request_hash[:params]['limit'] = limit.to_s if limit
      request_hash[:params]['page'] = page.to_s if page
      options[:request] = request_hash
    end

    pagy(:offset, scope, count: count, **options)
  end

  # Paginate without running a COUNT query.
  # Fetches limit + 1 to determine if a next page exists.
  # Returns [Pagy::Countless, Array].
  def pagy_countless_from_scope(scope, limit: nil, page: nil, **options)
    # If limit/page are explicitly provided (tests), pass them via request hash
    if limit || page
      request_hash = { params: {} }
      request_hash[:params]['limit'] = limit.to_s if limit
      request_hash[:params]['page'] = page.to_s if page
      options[:request] = request_hash
    end

    # Pagy::Countless only supports :empty_page or :exception overflow options
    # (not :last_page which is the global default)
    pagy(:countless, scope, overflow: :empty_page, **options)
  end
end
