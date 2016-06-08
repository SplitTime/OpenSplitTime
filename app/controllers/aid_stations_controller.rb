class AidStationsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_aid_station
  after_action :verify_authorized

  def show
    authorize @aid_station
    session[:return_to] = aid_station_path(@aid_station)
  end

  def edit
    authorize @aid_station
  end

  def update
    authorize @aid_station

    if @aid_station.update(aid_station_params)
      redirect_to session.delete(:return_to) || @aid_station
    else
      render 'edit'
    end
  end

  def destroy
    authorize @aid_station
    if @aid_station.events.present?
      flash[:danger] = 'Aid_station cannot be deleted if events are present on the aid_station. Delete the related events individually and then delete the aid_station.'
    else
      @aid_station.destroy
      flash[:success] = 'Aid_station deleted.'
    end

    session[:return_to] = params[:referrer_path] if params[:referrer_path]
    redirect_to session.delete(:return_to) || aid_stations_path
  end


  private

  def aid_station_params
    params.require(:aid_station).permit(:event_id, :split_id, :status, :open_time, :close_time,
                                        :captain_name, :comms_chief_name, :comms_frequencies)
  end
  
  def set_aid_station
    @aid_station = AidStation.find(params[:id])
  end


end