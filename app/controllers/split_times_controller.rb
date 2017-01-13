class SplitTimesController < ApplicationController
  before_action :authenticate_user!, except: [:index, :show]
  before_action :set_split_time, except: [:index, :new, :create]
  after_action :verify_authorized, except: [:index, :show]

  def index

  end

  def show
    session[:return_to] = split_time_path(@split_time)
  end

  def new
    @split_time = SplitTime.new
    @effort = Effort.find(params[:effort_id]) if params[:effort_id]
    authorize @split_time
  end

  def edit
    @effort = @split_time.effort
    authorize @split_time
  end

  def create
    @split_time = SplitTime.new(split_time_params)
    authorize @split_time

    if @split_time.save
      redirect_to session.delete(:return_to) || edit_split_times_effort_path(@split_time.effort)
    else
      redirect_to session.delete(:return_to) || edit_split_times_effort_path(@split_time.effort)
    end
  end

  def update
    authorize @split_time

    if @split_time.update(split_time_params)
      redirect_to session.delete(:return_to) || edit_split_times_effort_path(@split_time.effort)
    else
      @effort = Effort.find(@split_time.effort_id) if @split_time.effort_id
      render 'edit'
    end
  end

  def destroy
    authorize @split_time
    @split_time.destroy
    EffortDataStatusSetter.set_data_status(effort: @split_time.effort)
    session[:return_to] = params[:referrer_path] if params[:referrer_path]
    redirect_to session.delete(:return_to) || split_times_path
  end

  private

  def split_time_params
    params.require(:split_time).permit(:effort_id, :split_id, :bitkey, :sub_split_bitkey, :time_from_start,
                                       :elapsed_time, :time_of_day, :military_time, :data_status, :lap)
  end

  def query_params
    params.permit(:effort_id, :split_id)
  end

  def set_split_time
    @split_time = SplitTime.find(params[:id])
  end
end
