class Api::V1::LiveTimesController < ApiController
  before_action :set_live_time, except: :create

  def show
    authorize @live_time
    render json: @live_time, include: prepared_params[:include], fields: prepared_params[:fields]
  end

  def create
    live_time = LiveTime.new(permitted_params)
    authorize live_time

    if live_time.save
      render json: live_time, status: :created
    else
      render json: {message: 'live_time not created', error: "#{live_time.errors.full_messages}"}, status: :bad_request
    end
  end

  def update
    authorize @live_time
    if @live_time.update(permitted_params)
      render json: @live_time
    else
      render json: {message: 'live_time not updated', error: "#{@live_time.errors.full_messages}"}, status: :bad_request
    end
  end

  def destroy
    authorize @live_time
    if @live_time.destroy
      render json: @live_time
    else
      render json: {message: 'live_time not destroyed', error: "#{@live_time.errors.full_messages}"}, status: :bad_request
    end
  end

  private

  def set_live_time
    @live_time = LiveTime.find(params[:id])
  end
end
