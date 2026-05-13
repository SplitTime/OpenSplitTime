class OrganizationUsagesController < ApplicationController
  before_action :authenticate_user!
  before_action :require_admin

  def index
    @presenter = OrganizationUsageIndexPresenter.new
  end

  def show
    @organization = Organization.friendly.find(params[:id])
    @presenter = OrganizationUsageShowPresenter.new(@organization)
  end

  private

  def require_admin
    return if current_user&.admin?

    flash[:alert] = "Access denied."
    redirect_to root_path
  end
end
