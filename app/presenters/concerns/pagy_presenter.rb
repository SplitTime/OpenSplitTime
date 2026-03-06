# frozen_string_literal: true

require 'pagy/classes/request'
require 'pagy/toolbox/paginators/offset'
require 'pagy/toolbox/paginators/countless'

# Pagy pagination support for presenters
# Include this module to add pagy pagination methods to presenters
#
# Both methods require explicit scope and request arguments.
# In production presenters, pass request from view_context.
# In tests, pass a request hash with params.
module PagyPresenter
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

    # Merge Pagy defaults with our options
    pagy_options = Pagy::OPTIONS.merge(options)
    
    # Wrap request in Pagy::Request if it's a hash
    pagy_options[:request] = if request.is_a?(Hash)
                                Pagy::Request.new(pagy_options.merge(request: request))
                              else
                                request
                              end
    
    # Add count to options
    pagy_options[:count] = count
    
    Pagy::OffsetPaginator.paginate(scope, pagy_options)
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
    # Merge Pagy defaults with our options
    pagy_options = Pagy::OPTIONS.merge(options)
    
    # Wrap request in Pagy::Request if it's a hash
    pagy_options[:request] = if request.is_a?(Hash)
                                Pagy::Request.new(pagy_options.merge(request: request))
                              else
                                request
                              end
    
    # Pagy::Offset::Countless only supports :empty_page or :exception overflow options
    # (not :last_page which is the global default)
    pagy_options[:overflow] = :empty_page
    
    Pagy::CountlessPaginator.paginate(scope, pagy_options)
  end
end
