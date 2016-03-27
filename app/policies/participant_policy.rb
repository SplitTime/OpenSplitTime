class ParticipantPolicy
  attr_reader :current_user, :model

  def initialize(current_user, model)
    @current_user = current_user
    @participant = model
  end

  def new?
    @current_user.present?
  end

  def edit?
    @current_user.authorized_to_edit?(@participant)
  end

  def create?
    @current_user.present?
  end

  def update?
    @current_user.authorized_to_edit?(@participant)
  end

  def destroy?
    @current_user.authorized_to_edit?(@participant)
  end

end
