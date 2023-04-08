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
        format.turbo_stream do
          presenter = EventSetupCoursePresenter.new(@event, view_context)

          render turbo_stream: turbo_stream.replace("event_course_splits",
                                                    partial: "event_course_splits",
                                                    locals: {
                                                      event: presenter.event,
                                                      splits: presenter.splits,
                                                      aid_stations_by_split_id: presenter.aid_stations_by_split_id,
                                                    }
          )
        end
      end
    else
      render "new", event_id: @event.id, status: :unprocessable_entity
    end
  end

  def update
    authorize @split

    if @split.update(permitted_params)
      redirect_to split_path(@split)
    else
      @course = Course.friendly.find(@split.course_id) if @split.course_id
      render "edit", status: :unprocessable_entity
    end
  end

  def destroy
    authorize @split
    @split.destroy

    redirect_to organization_course_path(@split.course.organization, @split.course, display_style: :splits)
  end

  private

  def set_event_and_course
    event_group = EventGroup.friendly.find(params[:event_group_id])
    @event = event_group.events.friendly.find(params[:event_id])
    @course = @event.course
  end

  def set_split
    @split = @course.splits.find(params[:id])
  end
end
