class EventGroupsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_event_group
  after_action :verify_authorized

  def show
    authorize @event_group
  end

  def edit
    authorize @event_group
  end

  def update
    authorize @event_group

    if @event_group.update(permitted_params)
      redirect_to session.delete(:return_to) || @event_group
    else
      render 'edit'
    end
  end

  def destroy
    authorize @event_group
    if @event_group.events.present?
      flash[:danger] = 'Event group cannot be deleted if events are present within the event_group. ' +
          'Delete the related events individually and then delete the event_group.'
    else
      @event_group.destroy
      flash[:success] = 'Event group deleted.'
    end

    session[:return_to] = params[:referrer_path] if params[:referrer_path]
    redirect_to session.delete(:return_to) || events_path
  end


  private

  def set_event_group
    @event_group = EventGroup.friendly.find(params[:id])
  end
end
