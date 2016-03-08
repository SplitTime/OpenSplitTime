class SplitsController < ApplicationController
  before_action :authenticate_user!, except: [:index, :show]
  after_action :verify_authorized, except: [:index, :show]

  def index
    @splits = Split.order(:course_id)
    respond_to do |format|
      format.html
      format.csv { send_data @splits.to_csv }
      format.xls
      format.json { send_data @splits.to_json }
    end
  end

  def show
    @split = Split.find(params[:id])
  end

  def new
    @split = Split.new
    if params[:course_id]
      @course = Course.find(params[:course_id])
    end
    authorize @split
  end

  def edit
    @split = Split.find(params[:id])
    @course = Course.find(params[:course_id]) if params[:course_id]
    session[:return_to] ||= request.referer
    authorize @split
  end

  def create
    @split = Split.new(split_params)
    authorize @split

    if @split.save
      redirect_to @split
    else
      render 'new'
    end
  end

  def update
    @split = Split.find(params[:id])
    authorize @split

    if @split.update(split_params)
      redirect_to session.delete(:return_to)
    else
      @course = Course.find(@split.course_id) if @split.course_id
      render 'edit'
    end
  end

  def destroy
    split = Split.find(params[:id])
    authorize split
    split.destroy

    redirect_url = (request.referer.include?("splits/#{split.id}") ? splits_url : :back)
    redirect_to redirect_url
  end

  private

  def split_params
    params.require(:split).permit(:course_id, :location_id, :name, :description, :distance_from_start,
                                  :sub_order, :vert_gain_from_start, :vert_loss_from_start, :kind)
  end

  def query_params
    params.permit(:name)
  end

end
