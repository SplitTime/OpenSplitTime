class ControlPanelPolicy < Struct.new(:user, :admin)

  def show?
    user.admin?
  end


end
