class Api::V1::SplitsController < ApiController
  before_action :set_split, except: :create

  def show
    authorize @split
    render json: @split
  end

  def create
    split = Split.new(split_params)
    authorize split

    if split.save
      render json: split
    else
      render json: {error: "#{split.errors.full_messages}"}
    end
  end

  def update
    authorize @split
    if @split.update(split_params)
      render json: @split
    else
      render json: {error: "#{@split.errors.full_messages}"}
    end
  end

  def destroy
    authorize @split
    if @split.destroy
      render json: @split
    else
      render json: {error: "#{@split.errors.full_messages}"}
    end
  end

  private

  def set_split
    @split = Split.find_by(id: params[:id])
  end

  def split_params
    params.require(:split).permit(:id, :course_id, :location_id, :distance_from_start, :vert_gain_from_start,
                                  :vert_loss_from_start, :kind, :base_name, :description, :sub_split_bitmap)
  end
end