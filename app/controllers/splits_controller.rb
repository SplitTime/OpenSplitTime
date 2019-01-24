class SplitsController < ApplicationController
  before_action :authenticate_user!, except: [:index, :show]
  before_action :set_split, except: [:index, :new, :create]
  after_action :verify_authorized, except: [:index, :show]

  def index
    order = prepared_params[:sort].presence || [:course_id, :distance_from_start]
    @splits = Split.order(order).where(prepared_params[:filter])

    respond_to do |format|
      format.html do
        @splits = @splits.paginate(page: prepared_params[:page], per_page: prepared_params[:per_page] || 25)
      end
      format.csv do
        builder = CsvBuilder.new(Split, @splits)
        send_data(builder.full_string, type: 'text/csv',
                  filename: "#{prepared_params[:filter].to_param}-#{builder.model_class_name}-#{Time.now.strftime('%Y-%m-%d')}.csv")
      end
    end
  end

  def show
    @presenter = SplitPresenter.new(@split, params, current_user)
  end

  def new
    @split = Split.new(course_id: params[:course_id])
    authorize @split
  end

  def edit
    authorize @split
  end

  def create
    @split = Split.new(permitted_params)
    authorize @split

    if @split.save
      redirect_to split_path(@split)
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
      redirect_to split_path(@split)
    else
      @course = Course.friendly.find(@split.course_id) if @split.course_id
      render 'edit'
    end
  end

  def destroy
    authorize @split
    @split.destroy

    redirect_to course_path(@split.course, display_style: :splits)
  end

  private

  def set_split
    @split = Split.friendly.find(params[:id])
    redirect_numeric_to_friendly(@split, params[:id])
  end
end
