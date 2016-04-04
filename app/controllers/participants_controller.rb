class ParticipantsController < ApplicationController
  before_action :authenticate_user!, except: [:subregion_options, :avatar_disclaim]
  before_action :set_participant, except: [:index, :new, :create, :create_from_efforts, :subregion_options]
  after_action :verify_authorized, except: [:index, :subregion_options, :avatar_disclaim, :create_from_efforts]

  before_filter do
    locale = params[:locale]
    Carmen.i18n_backend.locale = locale if locale
  end

  def subregion_options
    render partial: 'subregion_select'
  end

  def index
    @participants = Participant.search(params[:search_param]).sort_by { |x| [x.last_name, x.first_name] }
                        .paginate(page: params[:page], per_page: 25)
    authorize @participants.first unless @participants.count < 1
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

  def create_from_efforts
    unreconciled_effort_id_array(params[:effort_ids], params[:event_id]).each do |effort_id|
      @participant = Participant.new
      @participant.pull_data_from_effort(effort_id)
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

  def unreconciled_effort_id_array(effort_ids, event_id)
    if effort_ids == "all"
      @event = Event.find(event_id)
      @event.unreconciled_efforts.order(:last_name).map &:id
    else
      effort_ids.is_a?(String) ? Array(effort_ids.to_i) : effort_ids
    end
  end

end
