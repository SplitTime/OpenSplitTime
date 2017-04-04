class RegistrationsController < Devise::RegistrationsController

  private

  def sign_up_params
    params.require(:user).permit(*UserParameters.permitted)
  end

  def account_update_params
    params.require(:user).permit(*(UserParameters.permitted << :current_password))
  end
end
