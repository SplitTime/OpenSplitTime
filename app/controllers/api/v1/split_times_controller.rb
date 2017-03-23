class Api::V1::SplitTimesController < ApiController
  before_action :set_split_time, except: :create

  def show
    authorize @split_time
    render json: @split_time, include: params[:include]
  end

  def create
    split_time = SplitTime.new(permitted_params)
    authorize split_time

    if split_time.save
      render json: split_time, status: :created
    else
      render json: {message: 'split_time not created', error: "#{split_time.errors.full_messages}"}, status: :bad_request
    end
  end

  def update
    authorize @split_time
    if @split_time.update(permitted_params)
      render json: @split_time
    else
      render json: {message: 'split_time not updated', error: "#{@split_time.errors.full_messages}"}, status: :bad_request
    end
  end

  def destroy
    authorize @split_time
    if @split_time.destroy
      render json: @split_time
    else
      render json: {message: 'split_time not destroyed', error: "#{@split_time.errors.full_messages}"}, status: :bad_request
    end
  end

  private

  def set_split_time
    @split_time = SplitTime.find(params[:id])
  end
end
