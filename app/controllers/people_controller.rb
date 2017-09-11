class PeopleController < ApplicationController
  before_action :authenticate_user!, except: [:index, :show, :subregion_options]
  before_action :set_person, except: [:index, :new, :create, :subregion_options]
  after_action :verify_authorized, except: [:index, :show, :subregion_options]

  before_action do
    locale = params[:locale]
    Carmen.i18n_backend.locale = locale if locale
  end

  def subregion_options
    render partial: 'subregion_select'
  end

  def index
    @people = policy_class::Scope.new(current_user, controller_class).viewable
                        .search(prepared_params[:search])
                        .with_age_and_effort_count
                        .ordered_by_name
                        .paginate(page: params[:page], per_page: 25)
    session[:return_to] = people_path
  end

  def show
    @presenter = PersonPresenter.new(@person, prepared_params)
    session[:return_to] = person_path(@person)
  end

  def new
    @person = Person.new
    authorize @person
  end

  def edit
    authorize @person
  end

  def create
    @person = Person.new(permitted_params)
    authorize @person

    if @person.save
      redirect_to session.delete(:return_to) || @person
    else
      render 'new'
    end
  end

  def update
    authorize @person

    if @person.update(permitted_params)
      redirect_to session.delete(:return_to) || @person
    else
      render 'edit'
    end
  end

  def destroy
    authorize @person
    @person.destroy

    redirect_to people_path
  end

  def avatar_claim
    authorize @person
    @person.update(claimant: current_user)
    redirect_to @person
  end

  def avatar_disclaim
    authorize @person
    @person.update(claimant: nil)
    redirect_to @person
  end

  def merge
    authorize @person
    @person_merge = PersonMergeView.new(@person, params[:proposed_match])
    if @person_merge.proposed_match.nil?
      flash[:success] = 'No potential matches detected.'
      redirect_to person_path(@person)
    end
  end

  def combine
    authorize @person
    if @person.merge_with(Person.find(params[:target_id]))
      flash[:success] = 'Merge was successful. '
    else
      flash[:danger] = 'Merge could not be completed.'
    end
    redirect_to merge_person_path(@person)
  end

  def remove_effort
    authorize @person
    @effort = Effort.friendly.find(params[:effort_id])
    @effort.person = nil
    @effort.save
    redirect_to person_path(@person)
  end

  def current_user_follow
    authorize @person
    @person.add_follower(@current_user)
  end

  def current_user_unfollow
    authorize @person
    @person.remove_follower(@current_user)
  end

  private

  def set_person
    @person = Person.friendly.find(params[:id])
  end
end
