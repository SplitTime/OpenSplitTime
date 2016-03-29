class ParticipantsController < ApplicationController
  before_action :authenticate_user!, except: [:subregion_options, :avatar_disclaim]
  before_action :set_participant, except: [:index, :new, :create, :create_from_effort, :subregion_options]
  after_action :verify_authorized, except: [:subregion_options, :avatar_disclaim, :create_from_effort]

  before_filter do
    locale = params[:locale]
    Carmen.i18n_backend.locale = locale if locale
  end

  def subregion_options
    render partial: 'subregion_select'
  end

  def index
    @participants = Participant.all.order(:last_name, :first_name)
    authorize @participants
    session[:return_to] = participants_path
  end
  
  def show
    authorize @participant
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

  def create_from_effort
    @effort = Effort.find(params[:effort_id])
    @participant = Participant.new
    participant_attributes = Participant.columns_for_create_from_effort
    participant_attributes.each do |attribute|
      @participant.assign_attributes({attribute => @effort[attribute]})
    end
    if @participant.save
      @effort.participant = @participant
      @effort.save
      redirect_to reconcile_event_path(params[:event_id])
    else
      redirect_to reconcile_event_path(params[:event_id]),
                  error: "Participant could not be created"
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

    session[:return_to] = params[:referrer_path] if params[:referrer_path]
    redirect_to session.delete(:return_to) || participants_path
  end

  def avatar_claim
    authorize @participant
    @participant.claimant = current_user
    @participant.save
    redirect_to @participant
  end

  def avatar_disclaim
    @participant.claimant = nil
    @participant.save
    redirect_to @participant
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
