class StewardshipsController < ApplicationController
  before_action :authenticate_user!
  after_action :verify_authorized

  def destroy
    @stewardship = Stewardship.find(params[:id])
    authorize @stewardship

    if @stewardship.destroy
      logger.info "#{@stewardship} destroyed"
    else
      logger.warn "#{@stewardship} not destroyed"
    end
    redirect_to stewards_organization_path(@stewardship.organization)
  end
end
