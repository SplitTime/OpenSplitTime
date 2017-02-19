class Api::V1::SplitTimesController < ApiController
  before_action :set_split_time, except: :create

  def show
    authorize @split_time
    render json: @split_time
  end

  def create
    split_time = SplitTime.new(split_time_params)
    authorize split_time

    if split_time.save
      render json: {message: 'split_time created', split_time: split_time}
    else
      render json: {message: 'split_time not created', error: "#{split_time.errors.full_messages}"}, status: :bad_request
    end
  end

  def update
    authorize @split_time
    if @split_time.update(split_time_params)
      render json: {message: 'split_time updated', split_time: @split_time}
    else
      render json: {message: 'split_time not updated', error: "#{@split_time.errors.full_messages}"}, status: :bad_request
    end
  end

  def destroy
    authorize @split_time
    if @split_time.destroy
      render json: {message: 'split_time destroyed', split_time: @split_time}
    else
      render json: {message: 'split_time not destroyed', error: "#{@split_time.errors.full_messages}"}, status: :bad_request
    end
  end

  private

  def set_split_time
    @split_time = SplitTime.find_by(id: params[:id])
    render json: {message: 'split_time not found'}, status: :not_found unless @split_time
  end

  def split_time_params
    params.require(:split_time).permit(*SplitTime::PERMITTED_PARAMS)
  end
end