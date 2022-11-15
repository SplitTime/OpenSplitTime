# frozen_string_literal: true

class CourseGroupsController < ApplicationController
  before_action :authenticate_user!, except: [:show]
  before_action :set_course_group, except: [:new, :create]
  before_action :set_organization
  after_action :verify_authorized, except: [:show]

  def show
    @presenter = ::CourseGroupPresenter.new(@course_group, view_context)
  end

  def new
    @course_group = @organization.course_groups.new
    authorize @course_group
  end

  def edit
    authorize @course_group
  end

  def create
    convert_checkbox_course_ids

    @course_group = @organization.course_groups.new(permitted_params)
    authorize @course_group

    if @course_group.save
      redirect_to organization_course_group_path(@organization, @course_group)
    else
      render "new", status: :unprocessable_entity
    end
  end

  def update
    authorize @course_group
    convert_checkbox_course_ids

    if @course_group.update(permitted_params)
      redirect_to organization_course_group_path(@organization, @course_group)
    else
      render "edit", status: :unprocessable_entity
    end
  end

  def destroy
    authorize @course_group

    if @course_group.destroy
      flash[:success] = "Course group deleted."
    else
      flash[:danger] = @course_group.errors.full_messages.join("\n")
    end

    redirect_to organization_path(@organization, display_style: :courses)
  end

  private

  def convert_checkbox_course_ids
    if params.dig(:course_group, :course_ids).is_a?(::ActionController::Parameters)
      params[:course_group][:course_ids] = params.dig(:course_group, :course_ids).select { |_, value| value == "1" }.keys
    end
  end

  def set_course_group
    @course_group = ::CourseGroup.friendly.find(params[:id])
  end

  def set_organization
    @organization = ::Organization.friendly.find(params[:organization_id])
  end
end
