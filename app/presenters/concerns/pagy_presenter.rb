# frozen_string_literal: true

# Pagy pagination support for presenters
# Include this module to add pagy pagination methods to presenters
module PagyPresenter
  # Paginate a scope using Pagy
  # Returns [pagy, records]
  #
  # @param scope [ActiveRecord::Relation] The scope to paginate
  # @param limit [Integer] Items per page (default: 25)
  # @param page [Integer] Current page number
  # @param count [Integer, nil] Total count (optional, will be calculated if not provided)
  # @return [Array<Pagy, ActiveRecord::Relation>]
  def pagy_from_scope(scope, limit: 25, page: 1, count: nil)
    count ||= scope.reorder(nil).count(:all)
    count = count.values.sum if count.is_a?(Hash)

    pagy = Pagy.new(count: count, page: page, limit: limit)
    records = scope.offset(pagy.offset).limit(pagy.limit)

    [pagy, records]
  end
end
