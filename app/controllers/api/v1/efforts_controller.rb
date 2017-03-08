class Api::V1::EffortsController < ApiController
  before_action :set_effort, except: :create

  def show
    authorize @effort
    @effort.split_times.load.to_a if params[:include].include?('split_times')
    render json: @effort, include: params[:include]
  end

  def create
    effort = Effort.new(effort_params)
    authorize effort

    if effort.save
      render json: effort, status: :created
    else
      render json: {message: 'effort not created', error: "#{effort.errors.full_messages}"}, status: :bad_request
    end
  end

  def update
    authorize @effort
    if @effort.update(effort_params)
      render json: @effort
    else
      render json: {message: 'effort not updated', error: "#{@effort.errors.full_messages}"}, status: :bad_request
    end
  end

  def destroy
    authorize @effort
    if @effort.destroy
      render json: @effort
    else
      render json: {message: 'effort not destroyed', error: "#{@effort.errors.full_messages}"}, status: :bad_request
    end
  end

  private

  def set_effort
    @effort = Effort.friendly.find(params[:id])
  end

  def effort_params
    params.require(:effort).permit(*Effort::PERMITTED_PARAMS)
  end
end