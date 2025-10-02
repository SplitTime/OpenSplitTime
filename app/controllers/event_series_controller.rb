class EventSeriesController < ApplicationController
  before_action :authenticate_user!, except: [:index, :show]
  before_action :set_organization
  before_action :authorize_organization, except: [:index, :show]
  before_action :set_event_series, except: [:index, :new, :create]
  after_action :verify_authorized, except: [:index, :show]

  def index
    @presenter = ::OrganizationPresenter.new(@organization, view_context)
  end

  def show
    event_series = @organization.event_series.where(id: @event_series).includes(events: :efforts).first
    @presenter = ::EventSeriesPresenter.new(event_series, view_context)
  end

  def new
    organization = ::Organization.where(id: @organization.id).includes(event_groups: { events: :efforts }).first

    @event_series = organization.event_series.new(results_template: ::ResultsTemplate.default)
  end

  def edit
    @event_series = @organization.event_series.where(id: @event_series).includes(events: :efforts).first
  end

  def create
    convert_checkbox_event_ids

    @event_series = @organization.event_series.new(permitted_params)

    if @event_series.save
      redirect_to organization_event_series_path(@organization, @event_series)
    else
      render "new", status: :unprocessable_content
    end
  end

  def update
    convert_checkbox_event_ids

    if @event_series.update(permitted_params)
      redirect_to organization_event_series_path(@organization, @event_series)
    else
      render "edit", status: :unprocessable_content
    end
  end

  def destroy
    if @event_series.destroy
      flash[:success] = "Event series deleted."
    else
      flash[:danger] = @event_series.errors.full_messages.join("\n")
    end

    redirect_to_organization
  end

  private

  def authorize_organization
    authorize @organization, policy_class: ::EventSeriesPolicy
  end

  def convert_checkbox_event_ids
    event_id_params = params.dig(:event_series, :event_ids)

    if event_id_params.is_a?(ActionController::Parameters)
      params[:event_series][:event_ids] = event_id_params.select { |_, value| value == "1" }.keys
    end
  end

  def redirect_to_organization
    redirect_to organization_path(@organization)
  end

  def set_event_series
    @event_series = @organization.event_series.friendly.find(params[:id])
  end

  def set_organization
    @organization = policy_scope(::Organization).friendly.find(params[:organization_id])
  end
end
