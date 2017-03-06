class Api::V1::ParticipantsController < ApiController
  before_action :set_participant, except: :create

  def show
    authorize @participant
    render json: @participant
  end

  def create
    participant = Participant.new(participant_params)
    authorize participant

    if participant.save
      render json: {message: 'participant created', participant: participant}
    else
      render json: {message: 'participant not created', error: "#{participant.errors.full_messages}"}, status: :bad_request
    end
  end

  def update
    authorize @participant
    if @participant.update(participant_params)
      render json: {message: 'participant updated', participant: @participant}
    else
      render json: {message: 'participant not updated', error: "#{@participant.errors.full_messages}"}, status: :bad_request
    end
  end

  def destroy
    authorize @participant
    if @participant.destroy
      render json: {message: 'participant destroyed', participant: @participant}
    else
      render json: {message: 'participant not destroyed', error: "#{@participant.errors.full_messages}"}, status: :bad_request
    end
  end

  private

  def set_participant
    @participant = Participant.friendly.find(params[:id])
  end

  def participant_params
    params.require(:participant).permit(*Participant::PERMITTED_PARAMS)
  end
end