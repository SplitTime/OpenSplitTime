class StewardshipsController < ApplicationController
  before_action :authenticate_user!
  after_action :verify_authorized

  def create
    # Raise an error if organization does not exist
    organization = Organization.friendly.find(params[:organization_id])
    user = User.find_by(email: params[:email])

    if user
      @stewardship = Stewardship.new(user: user, organization: organization)
      authorize @stewardship

      unless @stewardship.save
        flash[:warning] = "User #{user.full_name} could not be added as a steward.\n#{@stewardship.errors.full_messages.join("\n")}"
      end
    else
      skip_authorization
      flash[:warning] = "No user with email #{params[:email]} was located."
    end

    redirect_to organization_path(organization, display_style: :stewards)
  end

  def destroy
    @stewardship = Stewardship.find(params[:id])
    authorize @stewardship

    if @stewardship.destroy
      logger.info "#{@stewardship} destroyed"
    else
      logger.warn "#{@stewardship} not destroyed"
    end

    redirect_to organization_path(@stewardship.organization, display_style: :stewards)
  end
end
