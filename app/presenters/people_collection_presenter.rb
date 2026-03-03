# frozen_string_literal: true

class PeopleCollectionPresenter < BasePresenter
  include PagyPresenter

  attr_reader :people, :pagy

  def initialize(people_scope, view_context)
    @people_scope = people_scope
    @view_context = view_context
    @params = view_context.prepared_params
  end

  def people
    return @people if defined?(@people)

    @pagy, @people = pagy_from_scope(people_scope, items: per_page, page: page)
    @people
  end

  def people_count
    @people_count ||= pagy.count
  end

  def next_page_url
    view_context.url_for(request.params.merge(page: pagy.next)) if pagy.next
  end

  private

  attr_reader :people_scope, :params, :view_context

  delegate :request, to: :view_context, private: true
end
