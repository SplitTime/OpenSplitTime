class SplitsController < ApplicationController
  before_action :authenticate_user!, except: [:index, :show]
  after_action :verify_authorized, except: [:index, :show]

  def index
    @splits = Split.all
  end

  def show
    @split = Split.find(params[:id])
  end

  def new
    @split = Split.new
    authorize @split
  end

  def edit
    @split = Split.find(params[:id])
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
      redirect_to @split
    else
      render 'edit'
    end
  end

  def destroy
    split = Split.find(params[:id])
    authorize split
    split.destroy

    redirect_to splits_path
  end

  private

  def split_params
    params.require(:split).permit(:course_id, :location_id, :name, :distance_from_start,
                                  :sub_order, :vert_gain_from_start, :vert_loss_from_start, :kind)
  end

  def query_params
    params.permit(:name)
  end

end
