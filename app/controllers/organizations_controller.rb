class OrganizationsController < ApplicationController
  before_action :authenticate_user!, except: [:index, :show]
  before_action :set_organization, except: [:index, :new, :create]
  after_action :verify_authorized, except: [:index, :show]

  def index
    @presenter = OrganizationsPresenter.new(view_context)

    respond_to do |format|
      format.html do
        session[:return_to] = organizations_path
      end

      format.json do
        records = @presenter.records_from_context
        html = params[:html_template].present? ? render_to_string(partial: params[:html_template], collection: records, as: :record, formats: [:html]) : ""
        render json: {records: records, html: html, links: {next: @presenter.next_page_url}}
      end
    end
  end

  def show
    params[:view] ||= 'events'
    @presenter = OrganizationPresenter.new(@organization, params, current_user)
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
      redirect_to @organization
    else
      render 'new'
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
