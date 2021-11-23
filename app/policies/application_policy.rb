# frozen_string_literal: true

class ApplicationPolicy
  class Scope
    attr_reader :user, :scope

    def initialize(user, scope)
      @user = user
      @scope = scope
      post_initialize
    end

    def resolve_editable
      if user&.admin?
        scope.all
      elsif user.nil?
        scope.none
      else
        authorized_to_edit_records
      end
    end
    alias editable resolve_editable

    def resolve_viewable
      if user&.admin?
        scope.all
      elsif user.nil?
        visible_records
      else
        authorized_to_view_records
      end
    end
    alias viewable resolve_viewable
    alias resolve resolve_viewable

    def visible_records
      scope.respond_to?(:visible) ? scope.visible : scope.all
    end

    # May be overridden by model policies
    def authorized_to_edit_records
      scope.none
    end

    # May be overridden by model policies
    def authorized_to_view_records
      visible_records
    end
  end

  attr_reader :user, :record

  def initialize(user, record)
    @user = user
    @record = record
    post_initialize(record)
  end

  def index?
    user.present?
  end

  def show?
    user.present?
  end

  def new?
    user.present?
  end

  def edit?
    user.authorized_to_edit?(record)
  end

  def create?
    user.present?
  end

  def update?
    user.authorized_to_edit?(record)
  end

  def destroy?
    user.authorized_fully?(record)
  end

  private

  def verify_authorization_was_delegated(organization, delegating_class)
    unless organization.is_a?(::Organization)
      raise AuthorizationNotDelegatedError, "A #{delegating_class} must be authorized using the parent Organization"
    end
  end

  class AuthorizationNotDelegatedError < Pundit::Error
  end
end
