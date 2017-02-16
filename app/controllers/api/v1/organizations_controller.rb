class Api::V1::OrganizationsController < ApiController
  before_action :set_organization, except: :create

  def show
    authorize @organization
    render json: @organization
  end

  def create
    organization = Organization.new(organization_params)
    authorize organization

    if organization.save
      render json: {message: 'organization created', organization: organization}
    else
      render json: {message: 'organization not created', error: "#{organization.errors.full_messages}"}, status: :bad_request
    end
  end

  def update
    authorize @organization
    if @organization.update(organization_params)
      render json: {message: 'organization updated', organization: @organization}
    else
      render json: {message: 'organization not updated', error: "#{@organization.errors.full_messages}"}, status: :bad_request
    end
  end

  def destroy
    authorize @organization
    if @organization.destroy
      render json: {message: 'organization destroyed', organization: @organization}
    else
      render json: {message: 'organization not destroyed', error: "#{@organization.errors.full_messages}"}, status: :bad_request
    end
  end

  private

  def set_organization
    @organization = Organization.find_by(id: params[:id])
    render json: {message: 'organization not found'}, status: :not_found unless @organization
  end

  def organization_params
    params.require(:organization).permit(Organization::PERMITTED_PARAMS)
  end
end