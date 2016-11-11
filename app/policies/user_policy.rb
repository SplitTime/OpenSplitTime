class UserPolicy
  attr_reader :current_user, :user

  def initialize(current_user, user)
    @current_user = current_user
    @user = user
  end

  def index?
    current_user.admin?
  end

  def show?
    current_user.admin? | (current_user == user)
  end

  def edit_preferences?
    current_user.admin? | (current_user == user)
  end

  def update_preferences?
    current_user.admin? | (current_user == user)
  end

  def update?
    current_user.admin?
  end

  def destroy?
    current_user.admin? && (current_user != user)
  end

  def add_interest?
    current_user.admin? | (current_user == user)
  end

  def remove_interest?
    current_user.admin? | (current_user == user)
  end

end
