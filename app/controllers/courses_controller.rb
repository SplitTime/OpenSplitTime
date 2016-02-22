class CoursesController < ApplicationController
  before_action :authenticate_user!, except: [:index, :show]
  after_action :verify_authorized, except: [:index, :show]

  def index
    @courses = Course.all
  end

  def show
    @course = Course.find(params[:id])
  end

  def new
    @course = Course.new
    authorize @course
  end

  def edit
    @course = Course.find(params[:id])
    authorize @course
  end

  def create
    @course = Course.new(course_params)
    authorize @course

    if @course.save
      redirect_to @course
    else
      render 'new'
    end
  end

  def update
    @course = Course.find(params[:id])
    authorize @course

    if @course.update(course_params)
      redirect_to @course
    else
      render 'edit'
    end
  end

  def destroy
    course = Course.find(params[:id])
    authorize course
    course.destroy

    redirect_to courses_path
  end

  private

  def course_params
    params.require(:course).permit(:name, :descriptisplits_attributes: [:id, :name, :distance_from_start, :kind])
  end

  def query_params
    params.permit(:name)
  end

end
