class OrganizationsController < ApplicationController
  before_action :authenticate_user!, except: [:index, :show]
  before_action :set_organization, except: [:index, :new, :create]
  after_action :verify_authorized, except: [:index, :show]

  def index
    @presenter = OrganizationsPresenter.new(view_context)

    respond_to do |format|
      format.html { session[:return_to] = organizations_path }
      format.turbo_stream
    end
  end

  def show
    params[:view] ||= "events"
    @presenter = ::OrganizationPresenter.new(@organization, view_context)
    session[:return_to] = organization_path(@organization)
  end

  def new
    @organization = Organization.new
    authorize @organization
  end

  def edit
    authorize @organization
  end

  def create
    @organization = Organization.new(permitted_params)
    authorize @organization

    if @organization.save
      redirect_to new_organization_event_group_path(@organization)
    else
      render "new", status: :unprocessable_content
    end
  end

  def update
    authorize @organization

    if @organization.update(permitted_params)
      redirect_to @organization
    else
      render "edit", status: :unprocessable_content
    end
  end

  def destroy
    authorize @organization

    if @organization.destroy
      flash[:success] = "Organization deleted."
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
