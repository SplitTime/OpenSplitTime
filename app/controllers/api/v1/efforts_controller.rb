class Api::V1::EffortsController < ApiController
  before_action :set_effort, except: :create

  def show
    authorize @effort
    render json: @effort
  end

  def create
    effort = Effort.new(effort_params)
    authorize effort

    if effort.save
      render json: {message: 'effort created', effort: effort}
    else
      render json: {message: 'effort not created', error: "#{effort.errors.full_messages}"}, status: :bad_request
    end
  end

  def update
    authorize @effort
    if @effort.update(effort_params)
      render json: {message: 'effort updated', effort: @effort}
    else
      render json: {message: 'effort not updated', error: "#{@effort.errors.full_messages}"}, status: :bad_request
    end
  end

  def destroy
    authorize @effort
    if @effort.destroy
      render json: {message: 'effort destroyed', effort: @effort}
    else
      render json: {message: 'effort not destroyed', error: "#{@effort.errors.full_messages}"}, status: :bad_request
    end
  end

  private

  def set_effort
    @effort = Effort.find_by(id: params[:id])
    render json: {message: 'effort not found'}, status: :not_found unless @effort
  end

  def effort_params
    params.require(:effort).permit(*Effort::PERMITTED_PARAMS)
  end
end