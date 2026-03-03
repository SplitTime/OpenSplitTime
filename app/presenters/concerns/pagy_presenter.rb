# frozen_string_literal: true

# Pagy pagination support for presenters
# Include this module to add pagy pagination methods to presenters
# Compatible with pagy 9.x and 43.x
module PagyPresenter
  # Paginate a scope using Pagy
  # Returns [pagy, records]
  #
  # @param scope [ActiveRecord::Relation] The scope to paginate
  # @param items [Integer] Items per page (default: 25)
  # @param page [Integer] Current page number
  # @param count [Integer, nil] Total count (optional, will be calculated if not provided)
  # @return [Array<Pagy, ActiveRecord::Relation>]
  def pagy_from_scope(scope, items: 25, page: 1, count: nil)
    # Calculate count if not provided
    # This is useful when the scope has GROUP BY or other aggregations
    # Remove ordering before counting to avoid SQL errors with complex SELECT clauses
    # that use aliases in ORDER BY
    count ||= scope.reorder(nil).count(:all)

    # Handle grouped queries that return a Hash instead of Integer
    count = count.values.sum if count.is_a?(Hash)

    # Pagy.new API is compatible with both 9.x and 43.x
    pagy = Pagy.new(count: count, page: page, items: items)
    # In Pagy v9, the attribute is .limit; in v43+ it's .items
    limit = pagy.respond_to?(:items) ? pagy.items : pagy.limit
    records = scope.offset(pagy.offset).limit(limit)
    
    [pagy, records]
  end
end
