class OrganizationPolicy
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
