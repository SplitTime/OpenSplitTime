class RegistrationsController < Devise::RegistrationsController

  private

  def sign_up_params
    params.require(:user).permit(*UserParameters::PERMITTED)
  end

  def account_update_params
    params.require(:user).permit(*(UserParameters::PERMITTED << :current_password))
  end
end
