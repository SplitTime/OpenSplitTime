# frozen_string_literal: true

class UsersCollectionPresenter < BasePresenter
  attr_reader :users

  def initialize(users_scope, view_context)
    @users_scope = users_scope
    @view_context = view_context
    @params = view_context.prepared_params
  end

  def users
    @users ||= users_scope.paginate(page: page, per_page: per_page)
  end

  def users_count
    @users_count ||= users.size
  end

  def next_page_url
    view_context.url_for(request.params.merge(page: page + 1)) if users_count == per_page
  end

  private

  attr_reader :users_scope, :params, :view_context

  delegate :current_user, :request, to: :view_context, private: true
end
