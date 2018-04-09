class EventGroupsController < ApplicationController
  before_action :authenticate_user!, except: [:index, :show]
  before_action :set_event_group, except: [:index]
  after_action :verify_authorized, except: [:index, :show]

  def index
    scoped_event_groups = EventGroupPolicy::Scope.new(current_user, EventGroup).viewable.search(params[:search])
    @event_groups = EventGroup.where(id: scoped_event_groups.map(&:id))
                        .includes(events: :efforts).includes(:organization)
                        .sort_by { |event_group| -event_group.start_time.to_i }
                        .paginate(page: params[:page], per_page: 25)
    @presenter = EventGroupsCollectionPresenter.new(@event_groups, params, current_user)
    session[:return_to] = event_groups_path
  end

  def show
    events = @event_group.events
    if events.one? && !params[:force_settings]
      redirect_to events.first
    end
    @presenter = EventGroupPresenter.new(@event_group, params, current_user)
  end

  def edit
    authorize @event_group
  end

  def update
    authorize @event_group
    @event_group.assign_attributes(permitted_params)

    if @event_group.concealed_changed?
      setter = EventConcealedSetter.new(event_group: @event_group, concealed: @event_group.concealed)
      setter.perform
      flash[:danger] = setter.response[:errors] unless setter.status == :ok
      redirect_to event_group_path(@event_group, force_settings: true)

    elsif @event_group.save
      redirect_to event_group_path(@event_group, force_settings: true)

    else
      render 'edit'
    end
  end

  def destroy
    authorize @event_group
    if @event_group.events.present?
      flash[:danger] = 'Event group cannot be deleted if events are present within the event group. ' +
          'Delete the related events individually and then delete the event group.'
      redirect_to @event_group
    else
      @event_group.destroy
      flash[:success] = 'Event group deleted.'
      session[:return_to] = params[:referrer_path] if params[:referrer_path]
      redirect_to session.delete(:return_to) || events_path
    end
  end

  private

  def set_event_group
    @event_group = EventGroup.friendly.find(params[:id])
    redirect_numeric_to_friendly(@event_group, params[:id])
  end
end
