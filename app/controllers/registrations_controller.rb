class RegistrationsController < Devise::RegistrationsController

  private

  def sign_up_params
    params.require(:user).permit(*User::PERMITTED_PARAMS)
  end

  def account_update_params
    params.require(:user).permit(*(User::PERMITTED_PARAMS << :current_password))
  end
end