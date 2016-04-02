class EventsController < ApplicationController
  before_action :authenticate_user!, except: [:index, :show]
  before_action :set_event, except: [:index, :new, :create]
  after_action :verify_authorized, except: [:index, :show]

  def index
    @events = Event.paginate(page: params[:page], per_page: 25).order(first_start_time: :desc)
    session[:return_to] = events_path
  end

  def import_splits
    authorize @event
    if Importer.split_import(params[:file], @event)
      flash[:success] = "Import successful"
    else
      flash[:danger] = "No split data detected"
    end

    redirect_to event_path(@event)
  end

  def import_efforts
    authorize @event
    if Importer.effort_import(params[:file], @event)
      flash[:success] = "Import successful"
    else
      flash[:danger] = "No effort data detected"
    end

    redirect_to event_path(@event)
  end

  def show
    @associated_splits = @event.splits.order(:distance_from_start, :sub_order)
    session[:return_to] = event_path(@event)
  end

  def new
    @event = Event.new
    authorize @event
  end

  def edit
    authorize @event
  end

  def create
    @event = Event.new(event_params)
    authorize @event

    if @event.save
      redirect_to session.delete(:return_to) || @event
    else
      render 'new'
    end
  end

  def update
    authorize @event

    if @event.update(event_params)
      redirect_to session.delete(:return_to) || @event
    else
      render 'edit'
    end
  end

  def destroy
    authorize @event
    @event.destroy

    session[:return_to] = params[:referrer_path] if params[:referrer_path]
    redirect_to session.delete(:return_to) || events_path
  end

  def splits
    authorize @event
    @associated_splits = @event.splits
                             .sort_by { |x| [x.distance_from_start, x.sub_order] }
    @other_splits = (@event.course.splits - @associated_splits)
                        .sort_by { |x| [x.distance_from_start, x.sub_order] }
  end

  def associate_split
    authorize @event
    @event_split = EventSplit.new(event_id: @event.id, split_id: params[:split_id])

    if @event_split.save
      redirect_to splits_event_url(id: @event.id)
    else
      redirect_to splits_event_url(id: @event.id),
                  error: "Split was not associated with event"
    end
  end

  def associate_splits
    authorize @event
    if params[:split_id_array].nil?
      redirect_to :back
    else
      params[:split_id_array].each do |split_id|
        @event_split = EventSplit.new(event_id: @event.id, split_id: split_id)
        @event_split.save
      end
      redirect_to splits_event_url(id: @event.id)
    end
  end

  def reconcile
    authorize @event
    @unreconciled_efforts = @event.unreconciled_efforts.order(:last_name)
  end

  private

  def event_params
    params.require(:event).permit(:course_id, :race_id, :name, :first_start_time)
  end

  def query_params
    params.permit(:name)
  end

  def set_event
    @event = Event.find(params[:id])
  end

end
