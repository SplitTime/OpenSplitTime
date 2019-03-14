class OrganizationsController < ApplicationController
  before_action :authenticate_user!, except: [:index, :show]
  before_action :set_organization, except: [:index, :new, :create]
  after_action :verify_authorized, except: [:index, :show]

  def index
    @organizations = OrganizationPolicy::Scope.new(current_user, Organization).viewable.order(:name)
                         .paginate(page: params[:page], per_page: 25)
    @presenter = OrganizationsPresenter.new(@organizations, params, current_user)
    session[:return_to] = organizations_path
  end

  def show
    params[:view] ||= 'events'
    @presenter = OrganizationPresenter.new(@organization, params, current_user)
    session[:return_to] = organization_path(@organization)
  end

  def edit
    authorize @organization
  end

  def create
    @organization = Organization.new(permitted_params)
    authorize @organization

    if @organization.save
      respond_to do |format|
        format.json { render json: {success: true, id: @organization.id, type: 'organization'}, status: :created }
      end
    else
      respond_to do |format|
        format.json { render json: {success: false, errors: jsonapi_error_object(@organization)}, status: :unprocessable_entity }
      end
    end
  end

  def update
    authorize @organization

    if @organization.update(permitted_params)
      redirect_to @organization
    else
      render 'edit'
    end
  end

  def destroy
    authorize @organization

    if @organization.destroy
      flash[:success] = 'Organization deleted.'
      redirect_to organizations_path
    else
      flash[:danger] = @organization.errors.full_messages.join("\n")
      redirect_to organization_path(@organization)
    end
  end

  private

  def set_organization
    @organization = Organization.friendly.find(params[:id])
    redirect_numeric_to_friendly(@organization, params[:id])
  end
end
