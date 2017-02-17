class OrganizationPolicy
  class Scope
    attr_reader :user, :scope

    def initialize(user, scope)
      @user = user
      @scope = scope
    end

    def resolve
      if user.admin?
        scope.all
      else
        owned_org_ids = scope.where(created_by: user.id).ids
        steward_org_ids = scope.joins(:stewardships).where(stewardships: {user_id: user.id}).ids
        scope.where(id: (owned_org_ids + steward_org_ids).uniq)
      end
    end
  end

  attr_reader :current_user, :organization

  def initialize(current_user, organization)
    @current_user = current_user
    @organization = organization
  end

  def show?
    current_user.present?
  end

  def new?
    current_user.present?
  end

  def edit?
    current_user.authorized_to_edit?(organization)
  end

  def create?
    current_user.present?
  end

  def update?
    current_user.authorized_to_edit?(organization)
  end

  def destroy?
    current_user.authorized_to_edit?(organization)
  end

  def stewards?
    current_user.authorized_to_edit?(organization)
  end

  def remove_steward?
    current_user.authorized_to_edit?(organization)
  end

  def post_event_course_org?
    current_user.authorized_to_edit?(organization)
  end
end
