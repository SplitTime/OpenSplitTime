# frozen_string_literal: true

class UsersCollectionPresenter < BasePresenter
  DEFAULT_PER_PAGE = 25

  attr_reader :users

  def initialize(users, view_context)
    @users = users
    @view_context = view_context
    @params = view_context.prepared_params
  end

  def next_page_url
    view_context.url_for(request.params.merge(page: page + 1)) if users.size == DEFAULT_PER_PAGE
  end

  private

  attr_reader :params, :view_context

  delegate :current_user, :request, to: :view_context, private: true
end
