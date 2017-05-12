class Api::V1::OrganizationsController < ApiController
  before_action :set_organization, except: [:index, :create]

  def show
    authorize @organization
    render json: @organization, include: prepared_params[:include], fields: prepared_params[:fields]
  end

  def create
    organization = Organization.new(permitted_params)
    authorize organization

    if organization.save
      render json: organization, status: :created
    else
      render json: {errors: ['organization not created'], detail: "#{organization.errors.full_messages}"}, status: :unprocessable_entity
    end
  end

  def update
    authorize @organization
    if @organization.update(permitted_params)
      render json: @organization
    else
      render json: {errors: ['organization not updated'], detail: "#{@organization.errors.full_messages}"}, status: :unprocessable_entity
    end
  end

  def destroy
    authorize @organization
    if @organization.destroy
      render json: @organization
    else
      render json: {errors: ['organization not destroyed'], detail: "#{@organization.errors.full_messages}"}, status: :unprocessable_entity
    end
  end

  private

  def set_organization
    @organization = Organization.friendly.find(params[:id])
  end
end
