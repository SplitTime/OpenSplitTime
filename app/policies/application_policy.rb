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
        scope.where(id: (owned_records.ids + delegated_records.ids).uniq)
      end
    end
    alias_method :editable, :resolve_editable

    def resolve_viewable
      if user&.admin?
        scope.all
      elsif user.nil?
        visible_records
      else
        scope.where(id: (visible_records.ids + owned_records.ids + delegated_records.ids).uniq)
      end
    end
    alias_method :viewable, :resolve_viewable

    def visible_records
      scope.respond_to?(:visible) ? scope.visible : scope
    end

    def owned_records
      scope.where(created_by: user.id)
    end

    # May be overridden by model policies
    def delegated_records
      scope.none
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
end
