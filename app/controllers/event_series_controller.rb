class EventSeriesController < ApplicationController
  before_action :authenticate_user!, except: [:show]
  before_action :set_event_series, except: [:new, :create]
  after_action :verify_authorized, except: [:show]

  def show
    event_series = EventSeries.where(id: @event_series).includes(:organization, :results_template, events: :efforts).first
    @presenter = EventSeriesPresenter.new(event_series, params, current_user)
  end

  def new
    organization = Organization.where(id: Organization.friendly.find(params[:organization]))
                       .includes(event_groups: {events: :efforts}).first

    if organization
      @event_series = EventSeries.new(organization: organization)
      authorize @event_series
    else
      flash[:warning] = 'A new event series must be created using an existing organization'
      redirect_to organizations_path
    end
  end

  def edit
    authorize @event_series
    @event_series = EventSeries.includes(:organization, events: :efforts).first
  end

  def create
    convert_checkbox_event_ids

    @event_series = EventSeries.new(permitted_params)
    authorize @event_series

    if @event_series.save
      redirect_to_organization
    else
      render 'new'
    end
  end

  def update
    authorize @event_series

    convert_checkbox_event_ids

    if @event_series.update(permitted_params)
      flash[:success] = 'Event series updated'
      redirect_to_organization
    else
      render 'edit'
    end
  end

  def destroy
    authorize @event_series

    if @event_series.destroy
      flash[:success] = 'Event series deleted.'
      redirect_to_organization
    else
      flash[:danger] = @event_series.errors.full_messages.join("\n")
      redirect_to_organization
    end
  end

  private

  def convert_checkbox_event_ids
    if params.dig(:event_series, :event_ids).is_a?(ActionController::Parameters)
      params[:event_series][:event_ids] = params.dig(:event_series, :event_ids).select { |_, value| value == '1' }.keys
    end
  end

  def set_event_series
    @event_series = EventSeries.friendly.find(params[:id])

    if request.path != event_series_path(@event_series)
      redirect_numeric_to_friendly(@event_series, params[:id])
    end
  end

  def redirect_to_organization
    redirect_to organization_path(@event_series.organization, display_style: :event_series)
  end
end
