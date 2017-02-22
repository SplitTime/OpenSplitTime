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
      render json: effort
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
    @effort = Effort.find_by(id: params[:id])
    render json: {message: 'effort not found'}, status: :not_found unless @effort
  end

  def effort_params
    params.require(:effort).permit(:id, :event_id, :participant_id, :wave, :bib_number, :city, :state_code, :country_code,
                                   :age, :first_name, :last_name, :gender, :birthdate, :start_offset, :dropped_split_id,
                                   :dropped_lap, :concealed, :beacon_url, :report_url, :photo_url)
  end
end