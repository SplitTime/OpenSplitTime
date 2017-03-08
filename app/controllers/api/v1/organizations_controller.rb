class Api::V1::OrganizationsController < ApiController
  before_action :set_organization, except: [:index, :create]

  # Returns only those organizations that the user is authorized to edit.
  def index
    authorize Organization
    render json: OrganizationPolicy::Scope.new(current_user, Organization).editable
  end

  def show
    authorize @organization
    render json: @organization, include: params[:include]
  end

  def create
    organization = Organization.new(organization_params)
    authorize organization

    if organization.save
      render json: organization, status: :created
    else
      render json: {message: 'organization not created', error: "#{organization.errors.full_messages}"}, status: :bad_request
    end
  end

  def update
    authorize @organization
    if @organization.update(organization_params)
      render json: @organization
    else
      render json: {message: 'organization not updated', error: "#{@organization.errors.full_messages}"}, status: :bad_request
    end
  end

  def destroy
    authorize @organization
    if @organization.destroy
      render json: @organization
    else
      render json: {message: 'organization not destroyed', error: "#{@organization.errors.full_messages}"}, status: :bad_request
    end
  end

  private

  def set_organization
    @organization = Organization.friendly.find(params[:id])
  end

  def organization_params
    params.require(:organization).permit(*Organization::PERMITTED_PARAMS)
  end
end
