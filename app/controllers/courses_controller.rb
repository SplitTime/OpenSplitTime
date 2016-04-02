class CoursesController < ApplicationController
  before_action :authenticate_user!, except: [:index, :show]
  before_action :set_course, except: [:index, :new, :create]
  after_action :verify_authorized, except: [:index, :show]

  def index
    @courses = Course.paginate(page: params[:page], per_page: 25).order(:name)
    session[:return_to] = courses_path
  end

  def show
    @course_splits = @course.splits.order(:distance_from_start, :sub_order)
    session[:return_to] = course_path(@course)
  end

  def new
    @course = Course.new
    authorize @course
  end

  def edit
    authorize @course
  end

  def create
    @course = Course.new(course_params)
    authorize @course

    if @course.save
      redirect_to session.delete(:return_to) || @course
    else
      render 'new'
    end
  end

  def update
    authorize @course

    if @course.update(course_params)
      redirect_to session.delete(:return_to) || @course
    else
      render 'edit'
    end
  end

  def destroy
    authorize @course
    @course.destroy

    session[:return_to] = params[:referrer_path] if params[:referrer_path]
    redirect_to session.delete(:return_to) || courses_path
  end

  private

  def course_params
    params.require(:course).permit(:name, :description, splits_attributes: [:id, :name, :distance_from_start, :kind])
  end

  def query_params
    params.permit(:name)
  end

  def set_course
    @course = Course.find(params[:id])
  end

end
