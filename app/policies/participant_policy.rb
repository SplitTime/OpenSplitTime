class ParticipantPolicy
  attr_reader :current_user, :model

  def initialize(current_user, model)
    @current_user = current_user
    @participant = model
  end

  def new?
    @current_user.admin?
  end

  def edit?
    @current_user.authorized_to_edit?(@participant)
  end

  def create?
    @current_user.admin?
  end

  def update?
    @current_user.authorized_to_edit?(@participant)
  end

  def destroy?
    @current_user.admin?
  end

  def avatar_claim?
    @current_user.authorized_to_claim?(@participant)
  end

  def avatar_disclaim?
    @current_user.admin?
  end

  def merge?
    @current_user.admin?
  end

  def combine?
    @current_user.admin?
  end

  def remove_effort?
    @current_user.admin?
  end

  def add_follower?
    @current_user.present?
  end

  def remove_follower?
    @current_user.present?
  end

end
