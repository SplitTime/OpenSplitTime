class CoursePolicy
  attr_reader :current_user, :model

  def initialize(current_user, model)
    @current_user = current_user
    @course = model
  end

  def new?
    @current_user.present?
  end

  def edit?
    @current_user.authorized_to_edit?(@course)
  end

  def create?
    @current_user.present?
  end

  def update?
    @current_user.authorized_to_edit?(@course)
  end

  def destroy?
    @current_user.admin? # Course destruction could affect events that belong to users other than the course owner
  end

  def plan_effort?
    @current_user.present?
  end

end
