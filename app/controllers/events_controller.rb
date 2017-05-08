class EventsController < ApplicationController
  before_action :authenticate_user!, except: [:index, :show, :spread, :place, :analyze, :drop_list]
  before_action :set_event, except: [:index, :new, :create]
  after_action :verify_authorized, except: [:index, :show, :spread, :place, :analyze, :drop_list]

  def index
    @events = Event.select_with_params(params[:search])
                  .paginate(page: params[:page], per_page: 25)
    session[:return_to] = events_path
  end

  def show
    @event_display = EventEffortsDisplay.new(event: @event, params: prepared_params)
    session[:return_to] = event_path(@event)
    render 'show'
  end

  def new
    if params[:course_id]
      @event = Event.new(course_id: params[:course_id], laps_required: 1)
      @course = Course.friendly.find(params[:course_id])
    else
      @event = Event.new(laps_required: 1)
    end
    authorize @event
  end

  def edit
    authorize @event
  end

  def create
    @event = Event.new(permitted_params)
    authorize @event

    if @event.save
      @event.set_all_course_splits
      redirect_to stage_event_path(@event)
    else
      render 'new'
    end
  end

  def update
    authorize @event

    if @event.update(permitted_params)
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

  def find_problem_effort
    authorize @event
    @effort = @event.efforts.invalid_status.shuffle.first
    if @effort
      redirect_to effort_path(@effort)
    else
      flash[:success] = "No problem efforts found for #{@event.name}."
      redirect_to stage_event_path(@event)
    end
  end


# Event staging actions

  def stage
    authorize @event
    @event_stage = EventStageDisplay.new(event: @event, params: prepared_params)
    params[:view] ||= 'efforts'
    session[:return_to] = stage_event_path(@event)
  end

  def reconcile
    authorize @event
    @unreconciled_batch = @event.unreconciled_efforts.order(:last_name).limit(20)
    if @unreconciled_batch.empty?
      redirect_to stage_event_path(@event)
    else
      @unreconciled_batch.each { |effort| effort.suggest_close_match }
    end
  end

  def create_participants
    authorize @event
    EventReconcileService.create_participants_from_efforts(params[:effort_ids])
    redirect_to reconcile_event_path(@event)
  end

  def delete_all_efforts
    authorize @event
    @event.efforts.destroy_all
    flash[:warning] = "All efforts deleted for #{@event.name}"
    redirect_to stage_event_path(@event)
  end

# Import actions

  def import_splits
    authorize @event
    file_url = BucketStoreService.upload_to_bucket('imports', params[:file], current_user.id)
    if file_url
      ImportSplitsJob.perform_later(file_url, @event, current_user.id)
      flash[:success] = 'Import in progress. Reload page for results.'
    else
      flash[:danger] = 'Import file too large.'
    end
    redirect_to stage_event_path(@event)
  end

  def import_splits_csv
    authorize @event
    file_url = BucketStoreService.upload_to_bucket('imports', params[:file], current_user.id)
    if file_url
      importer = CsvImporter.new(file_path: file_url,
                                 model: :splits,
                                 global_attributes: {course: @event.course, created_by: current_user.id})
      importer.import
      respond_to do |format|
        if importer.errors.empty?
          format.html { flash[:success] = "Imported #{importer.saved_records.size} splits." and redirect_to :back }
          format.json { render json: importer.saved_records, status: importer.response_status }
        else
          format.html { flash[:warning] = "The following errors were found: #{importer.errors}" and redirect_to :back }
          format.json { render json: {errors: importer.errors}, status: importer.response_status }
        end
      end
    else
      flash[:danger] = 'Import file too large.'
    end
  end

  def import_efforts
    authorize @event
    file_url = BucketStoreService.upload_to_bucket('imports', params[:file], current_user.id)
    if file_url
      uid = 1
      background_channel = "import_progress_#{uid}"
      ImportEffortsJob.perform_later(file_url, @event, current_user.id,
                                     params.slice(:time_format, :with_times, :with_status), background_channel)
      flash[:success] = 'Import in progress. Reload the page in a minute or two ' +
          '(depending on file size) and your import should be complete.'
    else
      flash[:danger] = 'The import file is too large. Delete extraneous data and ' +
          'if it is still too large, divide the file and import in multiple steps.'
    end
    redirect_to stage_event_path(@event)
  end

  def spread
    @spread_display = EventSpreadDisplay.new(event: @event, params: prepared_params)
    respond_to do |format|
      format.html
      format.csv do
        authorize @event
        csv_stream = render_to_string(partial: 'spread.csv.ruby')
        send_data(csv_stream, type: 'text/csv',
                  filename: "#{@event.name}-#{@spread_display.display_style}-#{Date.today}.csv")
      end
    end
  end

# Actions related to the event/split relationship

  def splits
    authorize @event
    @other_splits = @event.course.ordered_splits - @event.splits
  end

  def associate_splits
    authorize @event
    if params[:split_ids].nil?
      redirect_to :back
    else
      params[:split_ids].each do |split_id|
        @event.splits << Split.find(split_id)
      end
      redirect_to splits_event_url(id: @event.id)
    end
  end

  def remove_splits
    authorize @event
    params[:split_ids].each { |split_id| @event.splits.delete(split_id) }
    redirect_to splits_event_path(@event)
  end

  def set_data_status
    authorize @event
    report = BulkDataStatusSetter.set_data_status(efforts: @event.efforts)
    flash[:warning] = report if report
    redirect_to stage_event_path(@event)
  end

  def set_dropped_attributes
    authorize @event
    report = @event.set_dropped_attributes
    flash[:warning] = report if report
    redirect_to stage_event_path(@event)
  end

  def start_all_efforts
    authorize @event
    report = BulkUpdateService.start_all_efforts(@event, @current_user.id)
    flash[:warning] = report if report
    redirect_to stage_event_path(@event)
  end

# Enable/disable availability for live views

  def live_enable
    authorize @event
    @event.update(available_live: true)
    redirect_to stage_event_path(@event)
  end

  def live_disable
    authorize @event
    @event.update(available_live: false)
    redirect_to stage_event_path(@event)
  end

  def add_beacon
    authorize @event
    update_beacon_url(params[:value])
    respond_to do |format|
      format.html { redirect_to stage_event_path(@event) }
      format.js { render inline: 'location.reload();' }
    end
  end

  def drop_list
    @event_dropped_display = EventDroppedDisplay.new(event: @event, params: prepared_params)
    session[:return_to] = event_path(@event)
  end

  def export_to_ultrasignup
    authorize @event
    params[:per_page] = @event.efforts.size # Get all efforts without pagination
    @event_display = EventEffortsDisplay.new(event: @event, params: prepared_params)
    respond_to do |format|
      format.html { redirect_to stage_event_path(@event) }
      format.csv do
        csv_stream = render_to_string(partial: 'ultrasignup.csv.ruby')
        send_data(csv_stream, type: 'text/csv',
                  filename: "#{@event.name}-for-ultrasignup-#{Date.today}.csv")
      end
    end
  end

  private

  def set_event
    @event = Event.friendly.find(params[:id])
  end

  def update_beacon_url(url)
    @event.update(beacon_url: url)
  end
end
