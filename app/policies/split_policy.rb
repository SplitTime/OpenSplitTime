class SplitPolicy
  attr_reader :current_user, :split

  def initialize(current_user, split)
    @current_user = current_user
    @split = split
  end

  def import?
    current_user.present?
  end

  def new?
    current_user.present?
  end

  def edit?
    current_user.authorized_to_edit?(split)
  end

  def create?
    current_user.present?
  end

  def update?
    current_user.authorized_to_edit?(split)
  end

  def destroy?
    current_user.admin?
  end

  def create_location?
    current_user.authorized_to_edit?(split)
  end

  def assign_location?
    current_user.authorized_to_edit?(split)
  end

end
