# frozen_string_literal: true

class UsersCollectionPresenter < BasePresenter
  include PagyPresenter

  attr_reader :users, :pagy

  def initialize(users_scope, view_context)
    @users_scope = users_scope
    @view_context = view_context
    @params = view_context.prepared_params
  end

  def users
    return @users if defined?(@users)

    @pagy, @users = pagy_from_scope(users_scope, limit: per_page, page: page)
    @users
  end

  def users_count
    @users_count ||= users.size
  end

  def next_page_url
    users
    view_context.url_for(request.params.merge(page: pagy.next)) if pagy.next
  end

  private

  attr_reader :users_scope, :params, :view_context

  delegate :current_user, :request, to: :view_context, private: true
end
