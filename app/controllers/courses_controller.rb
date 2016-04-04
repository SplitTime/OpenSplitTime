class CoursesController < ApplicationController
  before_action :authenticate_user!, except: [:index, :show, :best_efforts]
  before_action :set_course, except: [:index, :new, :create]
  after_action :verify_authorized, except: [:index, :show, :best_efforts]

  def index
    @courses = Course.paginate(page: params[:page], per_page: 25).order(:name)
    session[:return_to] = courses_path
  end

  def show
    @course_splits = @course.splits.ordered
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
      session[:return_to] = courses_path
      redirect_to course_path(@course)
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

  def best_efforts
    sorted_finishes = @course.all_finishes_sorted
    @efforts = sorted_finishes.paginate(page: params[:page], per_page: 25)
    session[:return_to] = best_efforts_course_path(@course)
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
