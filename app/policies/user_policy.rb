class UserPolicy < ApplicationPolicy
  class Scope < ApplicationPolicy::Scope
    attr_reader :current_user

    def post_initialize
      @current_user = user
    end

    def resolve_editable
      if current_user.admin?
        scope.all
      else
        scope.where(id: current_user.id)
      end
    end

    def resolve_viewable
      resolve_editable
    end
  end

  attr_reader :current_user, :user_record

  def post_initialize(user_record)
    @current_user = user
    @user_record = user_record
  end

  def index?
    current_user.admin?
  end

  def update?
    index?
  end

  def destroy?
    current_user.admin? && (current_user != user_record)
  end

  def current?
    current_user.present?
  end
end
