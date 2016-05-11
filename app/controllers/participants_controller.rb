class ParticipantsController < ApplicationController
  before_action :authenticate_user!, except: [:index, :show, :subregion_options, :avatar_disclaim]
  before_action :set_participant, except: [:index, :new, :create, :create_from_efforts, :subregion_options]
  after_action :verify_authorized, except: [:index, :show, :subregion_options, :avatar_disclaim, :create_from_efforts]

  before_filter do
    locale = params[:locale]
    Carmen.i18n_backend.locale = locale if locale
  end

  def subregion_options
    render partial: 'subregion_select'
  end

  def index
    @participants = Participant.search(params[:search_param])
                        .with_age_and_effort_count
                        .order(:last_name, :first_name)
                        .paginate(page: params[:page], per_page: 25)
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

  def create_from_efforts
    @efforts = Effort.where(id: params[:effort_ids])
    @efforts.each do |effort|
      @participant = Participant.new
      @participant.pull_data_from_effort(effort)
    end
    redirect_to reconcile_event_path(params[:event_id])
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

  def merge
    authorize @participant
    @proposed_match = params[:proposed_match] ? Participant.find(params[:proposed_match]) : @participant.possible_duplicates.first
    if @proposed_match
      @proposed_matches = @participant.possible_duplicates - [@proposed_match]
    else
      flash[:success] = "No potential matches detected."
      redirect_to participant_path(@participant)
    end
  end

  def combine
    authorize @participant
    @participant.merge_with(Participant.find(params[:target_id]))
    redirect_to merge_participant_path(@participant)
  end

  def remove_effort
    authorize @participant
    @effort = Effort.find(params[:effort_id])
    @effort.participant = nil
    @effort.save
    redirect_to participant_path(@participant)
  end

  private

  def participant_params
    params.require(:participant).permit(:search_param, :first_name, :last_name, :gender, :birthdate,
                                        :city, :state_code, :country_code, :email, :phone)
  end

  def query_params
    params.permit(:search_param, :first_name, :last_name, :gender, :birthdate,
                  :city, :state_code, :country_code, :email, :phone)
  end

  def set_participant
    @participant = Participant.find(params[:id])
  end

end
