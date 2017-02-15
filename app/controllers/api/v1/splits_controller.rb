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
      render json: {message: 'split created', split: split}
    else
      render json: {message: 'split not created', error: "#{split.errors.full_messages}"}, status: :bad_request
    end
  end

  def update
    authorize @split
    if @split.update(split_params)
      render json: {message: 'split updated', split: @split}
    else
      render json: {message: 'split not updated', error: "#{@split.errors.full_messages}"}, status: :bad_request
    end
  end

  def destroy
    authorize @split
    if @split.destroy
      render json: {message: 'split destroyed', split: @split}
    else
      render json: {message: 'split not destroyed', error: "#{@split.errors.full_messages}"}, status: :bad_request
    end
  end

  private

  def set_split
    @split = Split.find_by(id: params[:id])
    render json: {message: 'split not found'}, status: :not_found unless @split
  end

  def split_params
    params.require(:split).permit(:id, :course_id, :split_id, :distance_from_start, :vert_gain_from_start,
                                  :vert_loss_from_start, :kind, :base_name, :description, :sub_split_bitmap)
  end
end