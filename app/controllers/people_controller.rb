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
    params[:sort] ||= 'last_name,first_name'
    @people = policy_class::Scope.new(current_user, controller_class).viewable
                        .search(prepared_params[:search])
                        .with_age_and_effort_count
                        .order(prepared_params[:sort_text])
                        .paginate(page: params[:page], per_page: 25)
    session[:return_to] = people_path
  end

  def show
    @presenter = PersonPresenter.new(@person, prepared_params, current_user)
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
      redirect_to @person
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
    target = Person.friendly.find(params[:target_id])
    response = Interactors::MergePeople.perform!(@person, target)
    set_flash_message(response)
    redirect_to person_path(@person)
  end

  private

  def set_person
    @person = policy_scope(Person).friendly.find(params[:id])
    redirect_numeric_to_friendly(@person, params[:id])
  end
end
