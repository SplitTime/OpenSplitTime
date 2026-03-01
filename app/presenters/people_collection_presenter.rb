# frozen_string_literal: true

class PeopleCollectionPresenter < BasePresenter
  DEFAULT_PER_PAGE = 25

  attr_reader :people

  def initialize(people_scope, view_context)
    @people_scope = people_scope
    @view_context = view_context
    @params = view_context.prepared_params
  end

  def people
    @people ||= people_scope
                  .paginate(page: page, per_page: per_page)
  end

  def people_count
    @people_count ||= people.size
  end

  def per_page
    result = params[:per_page]&.to_i || DEFAULT_PER_PAGE
    result == 0 ? DEFAULT_PER_PAGE : result
  end

  def next_page_url
    view_context.url_for(request.params.merge(page: page + 1)) if people_count == per_page
  end

  private

  attr_reader :people_scope, :params, :view_context

  delegate :request, to: :view_context, private: true
end
