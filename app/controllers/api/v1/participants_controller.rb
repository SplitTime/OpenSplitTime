class Api::V1::ParticipantsController < ApiController
  before_action :set_participant, except: :create

  def show
    authorize @participant
    render json: @participant, include: prepared_params[:include], fields: prepared_params[:fields]
  end

  def create
    participant = Participant.new(permitted_params)
    authorize participant

    if participant.save
      render json: participant, status: :created
    else
      render json: {errors: ['participant not created'], detail: "#{participant.errors.full_messages}"}, status: :unprocessable_entity
    end
  end

  def update
    authorize @participant
    if @participant.update(permitted_params)
      render json: @participant
    else
      render json: {errors: ['participant not updated'], detail: "#{@participant.errors.full_messages}"}, status: :unprocessable_entity
    end
  end

  def destroy
    authorize @participant
    if @participant.destroy
      render json: @participant
    else
      render json: {errors: ['participant not destroyed'], detail: "#{@participant.errors.full_messages}"}, status: :unprocessable_entity
    end
  end

  private

  def set_participant
    @participant = Participant.friendly.find(params[:id])
  end
end
