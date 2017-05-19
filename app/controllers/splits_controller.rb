class SplitsController < ApplicationController
  before_action :authenticate_user!, except: [:index, :show]
  before_action :set_split, except: [:index, :new, :create]
  after_action :verify_authorized, except: [:index, :show]

  def index
    respond_to do |format|
      format.html do
        @splits = Split.paginate(page: params[:page], per_page: params[:per_page] || 25)
                      .order(:course_id, :distance_from_start)
        session[:return_to] = splits_path
      end
      format.csv do
        @presenter = CsvPresenter.new(model: controller_class_name.underscore, params: prepared_params)
        csv_stream = render_to_string(partial: 'shared/index.csv.ruby')
        send_data(csv_stream, type: 'text/csv',
                  filename: "#{controller_class_name.underscore}-#{Time.now}.csv")
      end
    end
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
    @split = Split.new(permitted_params)
    authorize @split

    if @split.save
      if params[:event_id]
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

    if @split.update(permitted_params)
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

  private

  def set_split
    @split = Split.friendly.find(params[:id])
  end
end
