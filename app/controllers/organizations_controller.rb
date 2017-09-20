class OrganizationsController < ApplicationController
  before_action :authenticate_user!, except: [:index, :show]
  before_action :set_organization, except: [:index, :new, :create]
  after_action :verify_authorized, except: [:index, :show]

  def index
    @organizations = policy_class::Scope.new(current_user, controller_class).viewable.order(:name)
                         .with_visible_event_count.paginate(page: params[:page], per_page: 25)
    session[:return_to] = organizations_path
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
    if @organization.event_groups.map(&:events).flatten.present?
      flash[:danger] = 'An organization cannot be deleted so long as any events are associated with it. ' +
          'Delete the related events individually and then delete the organization.'
      redirect_to organization_path(@organization)
    else
      @organization.destroy
      flash[:success] = 'Organization deleted.'
      redirect_to organizations_path
    end
  end

  def stewards
    authorize @organization
    if params[:search].present?
      user = User.find_by(email: params[:search])
      if user
        if @organization.stewards.include?(user)
          flash[:warning] = 'That user is already a steward of this organization.'
        else
          @organization.add_stewardship(user)
        end
        params[:search] = nil
      else
        flash[:warning] = 'User was not located.'
      end
    end
    session[:return_to] = stewards_organization_path
  end

  def remove_steward
    authorize @organization
    user = User.friendly.find(params[:user_id])
    @organization.remove_stewardship(user)
    redirect_to stewards_organization_path
  end

  private

  def set_organization
    @organization = Organization.friendly.find(params[:id])
  end
end
