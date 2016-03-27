class ParticipantsController < ApplicationController
  before_action :authenticate_user!, except: [:index, :show, :subregion_options]
  before_action :set_participant, except: [:index, :new, :create, :subregion_options]
  after_action :verify_authorized, except: [:index, :show, :subregion_options]

  before_filter do
    locale = params[:locale]
    Carmen.i18n_backend.locale = locale if locale
  end

  def subregion_options
    render partial: 'subregion_select'
  end

  def index
    @participants = Participant.all.order(:last_name, :first_name)
    session[:return_to] = participants_path
  end
  
  def show
    session[:return_to] = participant_path(@participant)
  end

  def new
    @participant = Participant.new
    authorize @participant
  end

  def edit
    authorize @participant
  end

  def create
    @participant = Participant.new(participant_params)
    authorize @participant

    if @participant.save
      redirect_to session.delete(:return_to) || @participant
    else
      render 'new'
    end
  end

  def update
    authorize @participant

    if @participant.update(participant_params)
      redirect_to session.delete(:return_to) || @participant
    else
      render 'edit'
    end
  end

  def destroy
    authorize @participant
    @participant.destroy

    redirect_to session.delete(:return_to) || participants_path
  end

  private

  def participant_params
    params.require(:participant).permit(:first_name, :last_name, :gender, :birthdate,
                                        :city, :state_code, :country_code, :email, :phone)
  end

  def query_params
    params.permit(:first_name, :last_name, :gender, :birthdate,
                  :city, :state_code, :country_code, :email, :phone)
  end

  def set_participant
    @participant = Participant.find(params[:id])
  end

end
