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
    @participants = Participant.search(params[:search])
                        .where(concealed: false)
                        .with_age_and_effort_count
                        .ordered_by_name
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

    redirect_to participants_path
  end

  def avatar_claim
    authorize @participant
    @participant.update(claimant: current_user)
    redirect_to @participant
  end

  def avatar_disclaim
    authorize @participant
    @participant.update(claimant: nil)
    redirect_to @participant
  end

  def merge
    authorize @participant
    @participant_merge = ParticipantMergeView.new(@participant, params[:proposed_match])
    if @participant_merge.proposed_match.nil?
      flash[:success] = "No potential matches detected."
      redirect_to participant_path(@participant)
    end
  end

  def combine
    authorize @participant
    if @participant.merge_with(Participant.find(params[:target_id]))
      flash[:success] = "Merge was successful. "
    else
      flash[:danger] = "Merge could not be completed."
    end
    redirect_to merge_participant_path(@participant)
  end

  def remove_effort
    authorize @participant
    @effort = Effort.friendly.find(params[:effort_id])
    @effort.participant = nil
    @effort.save
    redirect_to participant_path(@participant)
  end

  def current_user_follow
    authorize @participant
    @participant.add_follower(@current_user)
    sleep(0.5) if Rails.env.development?
  end

  def current_user_unfollow
    authorize @participant
    @participant.remove_follower(@current_user)
    sleep(0.5) if Rails.env.development?
  end

  private

  def participant_params
    params.require(:participant).permit(*Participant::PERMITTED_PARAMS)
  end

  def query_params
    params.permit(:search, :first_name, :last_name, :gender, :birthdate,
                  :city, :state_code, :country_code, :email, :phone)
  end

  def set_participant
    @participant = Participant.friendly.find(params[:id])
  end

end
