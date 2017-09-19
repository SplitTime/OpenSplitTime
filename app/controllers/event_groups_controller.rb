class EventGroupsController < ApplicationController
  before_action :authenticate_user!, except: [:show]
  before_action :set_event_group
  after_action :verify_authorized, except: [:show]

  def show
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
      redirect_to session.delete(:return_to) || @event_group

    elsif @event_group.save
      redirect_to session.delete(:return_to) || @event_group

    else
      render 'edit'
    end
  end

  def destroy
    authorize @event_group
    if @event_group.events.present?
      flash[:danger] = 'Event group cannot be deleted if events are present within the event group. ' +
          'Delete the related events individually and then delete the event group.'
      redirect_to event_group_path(@event_group)
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
  end
end
