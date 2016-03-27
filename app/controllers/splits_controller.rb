class SplitsController < ApplicationController
  before_action :authenticate_user!, except: [:index, :show]
  before_action :set_split, except: [:index, :new, :create]
  after_action :verify_authorized, except: [:index, :show]

  def index
    @splits = Split.order(:course_id, :distance_from_start, :sub_order)
    respond_to do |format|
      format.html
      format.csv { send_data @splits.to_csv }
      format.xls
      format.json { send_data @splits.to_json }
    end
    session[:return_to] = event_path(params[:event_id]) if params[:event_id].present?
    session[:return_to] = course_path(params[:course_id]) if params[:course_id].present?
  end

  def show
    session[:return_to] = split_path(@split)
  end

  def new
    @split = Split.new
    if params[:course_id]
      @course = Course.find(params[:course_id])
    end
    authorize @split
    session[:return_to] ||= request.referer
  end

  def edit
    @course = Course.find(params[:course_id]) if params[:course_id]
    session[:return_to] ||= request.referer
    authorize @split
  end

  def create
    @split = Split.new(split_params)
    authorize @split

    if @split.save
      conform_split_locations_to(@split) unless @split.location_id.nil?
      redirect_to session.delete(:return_to) || @split
    else
      render 'new'
    end
  end

  def update
    authorize @split

    if @split.update(split_params)
      conform_split_locations_to(@split)
      redirect_to session.delete(:return_to) || @split
    else
      @course = Course.find(@split.course_id) if @split.course_id
      render 'edit'
    end
  end

  def destroy
    authorize @split
    @split.destroy

    redirect_to session.delete(:return_to) || splits_url
  end

  private

  def split_params
    params.require(:split).permit(:course_id, :location_id, :name, :description, :distance_from_start,
                                  :sub_order, :vert_gain_from_start, :vert_loss_from_start, :kind)
  end

  def query_params
    params.permit(:name)
  end

  def set_split
    @split = Split.find(params[:id])
  end

end
