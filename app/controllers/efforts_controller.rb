class EffortsController < ApplicationController
  before_action :authenticate_user!, except: [:index, :show]
  before_action :set_effort, except: [:index, :new, :create, :associate_participants]
  after_action :verify_authorized, except: [:index, :show]

  def index

  end

  def show
    session[:return_to] = effort_path(@effort)
  end

  def new
    @effort = Effort.new
    @event = Event.find(params[:event_id]) if params[:event_id]
    authorize @effort
  end

  def edit
    @event = Event.find(@effort.event_id)
    authorize @effort
  end

  def create
    @effort = Effort.new(effort_params)
    authorize @effort

    if @effort.save
      redirect_to session.delete(:return_to) || @effort
    else
      render 'new'
    end
  end

  def update
    authorize @effort

    if @effort.update(effort_params)
      redirect_to session.delete(:return_to) || @effort
    else
      render 'edit'
    end
  end

  def destroy
    authorize @effort
    @effort.destroy
    session[:return_to] = params[:referrer_path] if params[:referrer_path]
    redirect_to session.delete(:return_to) || root_path
  end

  def associate_participant
    @event = Event.find(params[:event_id])
    authorize @event
    @effort.participant_id = params[:participant_id]

    if @effort.save
      @participant = Participant.find(params[:participant_id])
      @participant.pull_data_from_effort(@effort)
      redirect_to reconcile_event_path(params[:event_id])
    else
      redirect_to reconcile_event_path(params[:event_id]),
                  error: 'Effort was not associated with participant'
    end
  end

  def associate_participants
    @event = Event.find(params[:event_id])
    authorize @event
    if params[:ids].nil?
      redirect_to reconcile_event_path(@event)
    else
      count = EventReconcileService.associate_participants(params[:ids])
      flash[:success] = "#{count} efforts reconciled." if count > 1
      redirect_to reconcile_event_path(@event)
    end
  end

  def edit_split_times
    authorize @effort
    session[:return_to] = effort_path(@effort)
  end

  def delete_split
    authorize @effort
    @split = Split.find(params[:split_id])
    @effort.split_times.where(split: @split).destroy_all
    DataStatusService.set_data_status(@effort)
    session[:return_to] = params[:referrer_path] if params[:referrer_path]
    redirect_to session.delete(:return_to) || effort_path(@effort)
  end

  def confirm_split
    authorize @effort
    @split = Split.find(params[:split_id])
    split_times = @effort.split_times.where(split: @split)
    if params[:status] == 'confirmed'
      split_times.confirmed!
    else
      split_times.good!
    end
    DataStatusService.set_data_status(@effort)
    session[:return_to] = params[:referrer_path] if params[:referrer_path]
    redirect_to session.delete(:return_to) || effort_path(@effort)
  end

  def set_data_status
    authorize @effort
    DataStatusService.set_data_status(@effort)
    redirect_to effort_path(@effort)
  end

  private

  def effort_params
    params.require(:effort).permit(:first_name, :last_name, :gender, :wave, :bib_number, :age,
                                   :city, :state_code, :country_code, :start_time, :finished,
                                   split_times_attributes: [:id, :split_id, :sub_split_id, :effort_id, :time_from_start,
                                                            :elapsed_time, :time_of_day, :military_time,
                                                            :data_status])
  end

  def query_params
    params.permit(:name)
  end

  def set_effort
    @effort = Effort.find(params[:id])
  end

end