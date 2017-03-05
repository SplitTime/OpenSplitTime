class SplitsController < ApplicationController
  include UnitConversions
  before_action :authenticate_user!, except: [:index, :show]
  before_action :set_split, except: [:index, :new, :create]
  after_action :verify_authorized, except: [:index, :show]

  def index
    @splits = Split.paginate(page: params[:page], per_page: 25).order(:course_id, :distance_from_start)
    session[:return_to] = splits_path
  end

  def show
    session[:return_to] = split_path(@split)
  end

  def new
    @split = Split.new
    authorize @split
  end

  def edit
    @course = @split.course
    authorize @split
  end

  def create
    @split = Split.new(split_params)
    authorize @split

    if @split.save
      if params[:commit] == 'Create Location'
        session[:return_to] = edit_split_path(@split, event_id: params[:event_id])
        redirect_to create_location_split_path(id: @split.id, event_id: params[:event_id]), method: :post
      elsif params[:event_id]
        @event = Event.friendly.find(params[:event_id])
        @event.splits << @split
        @event.save
        redirect_to stage_event_path(@event)
      else
        redirect_to session.delete(:return_to) || @split.course
      end
    else
      if @event
        render 'new', event_id: @event.id
      elsif @course
        render 'new', course_id: @course.id
      else
        render 'new'
      end
    end
  end

  def update
    authorize @split

    if @split.update(split_params)
      if params[:event_id]
        @event = Event.friendly.find(params[:event_id])
        @event.splits << @split
        @event.save
      end
      redirect_to session.delete(:return_to) || @split.course
    else
      @course = Course.friendly.find(@split.course_id) if @split.course_id
      render 'edit'
    end
  end

  def destroy
    authorize @split
    course = Course.friendly.find(@split.course)
    @split.destroy

    redirect_to course_path(course)
  end

  def create_location
    authorize @split
    @split.location = Location.create(name: @split.random_location_name)
      session[:return_to] = params[:referrer_path] || split_path(@split)
    if @split.save
      redirect_to edit_location_path(@split.location, created_by_split: true)
    else
      flash[:danger] = "Could not create location."
      redirect_to session.delete(:return_to) || split_path(@split)
    end
  end

  def assign_location
    authorize @split
  end

  private

  def split_params
    params.require(:split).permit(*Split::PERMITTED_PARAMS)
  end

  def set_split
    @split = Split.find(params[:id])
  end

end
