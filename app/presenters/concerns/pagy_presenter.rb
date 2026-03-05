# frozen_string_literal: true

# Pagy pagination support for presenters
# Include this module to add pagy pagination methods to presenters
module PagyPresenter
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

    pagy = Pagy::Offset.new(count: count, page: page, limit: limit)
    records = scope.offset(pagy.offset).limit(pagy.limit)

    [pagy, records]
  end

  # Paginate without running a COUNT query.
  # Fetches limit + 1 to determine if a next page exists.
  # Returns [Pagy::Countless, Array].
  def pagy_countless_from_scope(scope, limit: 25, page: 1)
    # Pagy::Offset::Countless only supports :empty_page or :exception overflow options
    # (not :last_page which is the global default)
    pagy = Pagy::Offset::Countless.new(page: page, limit: limit, overflow: :empty_page)
    records = pagy.records(scope)
    [pagy, records]
  end
end
