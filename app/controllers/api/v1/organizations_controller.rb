class Api::V1::OrganizationsController < ApiController
  before_action :set_organization, except: [:index, :create]

  def show
    authorize @organization
    render json: @organization, include: params[:include], fields: params[:fields]
  end

  def create
    organization = Organization.new(permitted_params)
    authorize organization

    if organization.save
      render json: organization, status: :created
    else
      render json: {message: 'organization not created', error: "#{organization.errors.full_messages}"}, status: :bad_request
    end
  end

  def update
    authorize @organization
    if @organization.update(permitted_params)
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
end
