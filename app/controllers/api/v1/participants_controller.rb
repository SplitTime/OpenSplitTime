class Api::V1::ParticipantsController < ApiController
  before_action :set_participant, except: :create

  def show
    authorize @participant
    render json: @participant, include: params[:include]
  end

  def create
    participant = Participant.new(permitted_params)
    authorize participant

    if participant.save
      render json: participant, status: :created
    else
      render json: {message: 'participant not created', error: "#{participant.errors.full_messages}"}, status: :bad_request
    end
  end

  def update
    authorize @participant
    if @participant.update(permitted_params)
      render json: @participant
    else
      render json: {message: 'participant not updated', error: "#{@participant.errors.full_messages}"}, status: :bad_request
    end
  end

  def destroy
    authorize @participant
    if @participant.destroy
      render json: @participant
    else
      render json: {message: 'participant not destroyed', error: "#{@participant.errors.full_messages}"}, status: :bad_request
    end
  end

  private

  def set_participant
    @participant = Participant.friendly.find(params[:id])
  end
end
