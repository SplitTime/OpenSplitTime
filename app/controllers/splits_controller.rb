class SplitsController < ApplicationController
  include UnitConversions
  before_action :authenticate_user!, except: [:index, :show]
  before_action :set_split, except: [:index, :new, :create, :best_efforts]
  after_action :verify_authorized, except: [:index, :show]

  def index
    @splits = Split.paginate(page: params[:page], per_page: 25).order(:course_id, :distance_from_start, :sub_order)
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
      conform_split_locations(@split)
      conform_vert(@split)
      set_sub_order(@split)
      if params[:commit] == 'Create Location'
        session[:return_to] = edit_split_path(@split, event_id: params[:event_id])
        redirect_to new_location_path(split_id: @split.id, event_id: params[:event_id])
      elsif params[:event_id]
        @event = Event.find(params[:event_id])
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
      conform_split_locations(@split)
      conform_vert(@split)
      set_sub_order(@split)
      if params[:event_id]
        @event = Event.find(params[:event_id])
        @event.splits << @split
        @event.save
      end
      redirect_to session.delete(:return_to) || @split.course
    else
      @course = Course.find(@split.course_id) if @split.course_id
      render 'edit'
    end
  end

  def destroy
    authorize @split
    @split.destroy

    session[:return_to] = params[:referrer_path] if params[:referrer_path]
    redirect_to session.delete(:return_to) || splits_path
  end

  def assign_location
    authorize @split
  end

  def best_efforts
    @segment = Segment.new(params[:split1].to_i, params[:split2].to_i)
    authorize @segment.begin_split
    params[:gender] ||= 'combined'
    @efforts = Effort.gender_group(@segment, params[:gender]).sorted_by_segment_time(@segment).paginate(page: params[:page], per_page: 25)
    session[:return_to] = best_efforts_course_path(@segment.course)
  end

  private

  def split_params
    params.require(:split).permit(:course_id, :location_id, :name, :description, :sub_order, :kind,
                                  :distance_from_start, :distance_as_entered,
                                  :vert_gain_from_start, :vert_gain_as_entered,
                                  :vert_loss_from_start, :vert_loss_as_entered)
  end

  def query_params
    params.permit(:name)
  end

  def set_split
    @split = Split.find(params[:id])
  end

end
