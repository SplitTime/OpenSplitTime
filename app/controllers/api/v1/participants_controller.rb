class Api::V1::ParticipantsController < ApiController
  before_action :set_participant

  def show
    authorize @participant
    render json: @participant
  end

  private

  def set_participant
    @participant = Participant.find(params[:id])
  end
end