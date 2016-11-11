class SplitTimePolicy
  attr_reader :current_user, :split_time

  def initialize(current_user, split_time)
    @current_user = current_user
    @split_time = split_time
  end

  def import?
    current_user.present?
  end

  def new?
    current_user.present?
  end

  def edit?
    current_user.authorized_to_edit?(split_time)
  end

  def create?
    current_user.present?
  end

  def update?
    current_user.authorized_to_edit?(split_time)
  end

  def destroy?
    current_user.authorized_to_edit?(split_time)
  end

end
