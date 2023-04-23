# frozen_string_literal: true

class SplitsController < ApplicationController
  before_action :authenticate_user!, except: [:index]
  before_action :set_event_and_course
  before_action :set_split, except: [:index, :new, :create]
  after_action :verify_authorized, except: [:index]

  def index
    template_only = prepared_params[:filter] == { "id" => "0" }
    order = prepared_params[:sort].presence || [:distance_from_start]
    @splits = template_only ? Split.none : @event.splits.order(order)

    respond_to do |format|
      format.csv do
        builder = CsvBuilder.new(Split, @splits)
        filename = if template_only
                     "ost-split-import-template.csv"
                   else
                     "#{@event.name.parameterize}-#{builder.model_class_name}-#{Time.now.strftime('%Y-%m-%d')}.csv"
                   end

        send_data(builder.full_string, type: "text/csv", filename: filename)
      end
    end
  end

  def new
    @split = @course.splits.new
    authorize @split
  end

  def edit
    authorize @split
  end

  def create
    @split = @course.splits.new(permitted_params)
    authorize @split

    if @split.save
      @event.aid_stations.create(split: @split)
      respond_to do |format|
        format.html { redirect_to event_group_event_course_setup_path(@event.event_group, @event) }
        format.turbo_stream { @presenter = EventSetupCoursePresenter.new(@event, view_context) }
      end
    else
      render "new", status: :unprocessable_entity
    end
  end

  def update
    authorize @split

    if @split.update(permitted_params)
      respond_to do |format|
        format.html { redirect_to setup_course_event_group_event_path(@event.event_group, @event) }
        format.turbo_stream do
          @event.reload
          @presenter = EventSetupCoursePresenter.new(@event, view_context)
        end
      end
    else
      render "edit", status: :unprocessable_entity
    end
  end

  def destroy
    authorize @split

    if @split.destroy
      respond_to do |format|
        format.html { redirect_to setup_course_event_group_event_path(@event.event_group, @event) }
        format.turbo_stream { render turbo_stream: turbo_stream.remove(helpers.dom_id(@split, helpers.dom_id(@event))) }
      end
    else
      redirect_to setup_course_event_group_event_path(@event.event_group, @event), status: :unprocessable_entity
    end
  end

  private

  def set_event_and_course
    event_group = EventGroup.friendly.find(params[:event_group_id])
    @event = event_group.events.friendly.find(params[:event_id])
    @course = @event.course
  end

  def set_split
    @split = @course.splits.friendly.find(params[:id])
  end
end
