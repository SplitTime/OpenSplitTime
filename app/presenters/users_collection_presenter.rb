# frozen_string_literal: true

class UsersCollectionPresenter < BasePresenter
  attr_reader :users

  def initialize(users, params, current_user)
    @users = users
    @params = params
    @current_user = current_user
  end

  private

  attr_reader :params, :current_user
end
