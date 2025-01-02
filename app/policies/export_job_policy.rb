class ExportJobPolicy < ApplicationPolicy
  class Scope < ApplicationPolicy::Scope
    def authorized_to_edit_records
      scope.owned_by(user)
    end

    def authorized_to_view_records
      scope.owned_by(user)
    end
  end

  attr_reader :import_job, :parent_resource

  def index?
    user.present?
  end

  def show?
    user.owner_of?(record)
  end

  def create?
    user.admin? || user.owner_of?(record)
  end

  def destroy?
    create?
  end
end
