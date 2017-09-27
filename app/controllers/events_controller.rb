class EventsController < ApplicationController
  before_action :authenticate_user!, except: [:index, :show, :spread, :podium, :place, :analyze, :drop_list]
  before_action :set_event, except: [:index, :new, :create]
  after_action :verify_authorized, except: [:index, :show, :spread, :podium, :place, :analyze, :drop_list]

  def index
    @events = policy_class::Scope.new(current_user, controller_class).viewable
                  .select_with_params(params[:search])
                  .order(start_time: :desc)
                  .paginate(page: params[:page], per_page: 25)
    @presenter = EventsCollectionPresenter.new(@events, params, current_user)
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
    @event.assign_attributes(permitted_params)
    response = Interactors::UpdateEventAndGrouping.perform!(@event)

    if response.successful?
      set_flash_message(response)
      redirect_to session.delete(:return_to) || stage_event_path(@event)
    else
      render 'edit'
    end
  end

  def destroy
    authorize @event
    @event.destroy

    redirect_to events_path
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

  def create_people
    authorize @event
    EventReconcileService.create_people_from_efforts(params[:effort_ids])
    redirect_to reconcile_event_path(@event)
  end

  def delete_all_efforts
    authorize @event
    @event.efforts.destroy_all
    flash[:warning] = "All efforts deleted for #{@event.name}"
    redirect_to stage_event_path(@event)
  end

# Import actions

  def import_csv
    authorize @event
    if params[:file]
      file_url = FileStore.public_upload('imports', params[:file], current_user.id)
      if file_url
        file_contents = FileStore.get(file_url)
        params[:data] = file_contents
      else
        respond_to do |format|
          format.html { flash[:danger] = 'Import file too large.' and redirect_to :back }
          format.json { render json: {errors: [{title: 'Import file too large'}]}, status: :unprocessable_entity }
        end
      end
    end

    data_format = params[:data_format]&.to_sym
    strict = params[:accept_records] != 'single'
    importer = DataImport::Importer.new(params[:data], data_format, event: @event, current_user_id: current_user.id, strict: strict)
    importer.import

    respond_to do |format|
      if importer.invalid_records.present?
        format.html { flash[:warning] = "#{importer.invalid_records.map { |resource| jsonapi_error_object(resource) }}" and redirect_to :back }
        format.json { render json: {errors: importer.invalid_records.map { |resource| jsonapi_error_object(resource) }},
                             status: :unprocessable_entity }
      else
        case data_format
        when :csv_splits
          splits = @event.splits.to_set
          importer.saved_records.each { |record| @event.splits << record unless splits.include?(record) }
        when :csv_efforts
          EffortsAutoReconcileJob.perform_later(event: @event)
        end
        format.html { flash[:success] = "Imported #{importer.saved_records.size} #{model}." and redirect_to :back }
        format.json { render json: importer.saved_records, status: :created }
      end
    end
  end

  def import_splits
    authorize @event
    file_url = FileStore.public_upload('imports', params[:file], current_user.id)
    if file_url
      ImportSplitsJob.perform_later(file_url, @event, current_user.id)
      flash[:success] = 'Import in progress. Reload page for results.'
    else
      flash[:danger] = 'Import file too large.'
    end
    redirect_to stage_event_path(@event)
  end

  def import_efforts
    authorize @event
    file_url = FileStore.public_upload('imports', params[:file], current_user.id)
    if file_url
      uid = session.id
      background_channel = "progress_#{uid}"
      ImportEffortsJob.perform_later(file_url, @event, current_user.id,
                                     params.slice(:time_format, :with_times, :with_status), background_channel)
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

  def podium
    template = Results::FillTemplate.perform(event: @event, template_name: 'Ramble')
    @presenter = PodiumPresenter.new(@event, template)
  end

# Actions related to the event/split relationship

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

  def start_ready_efforts
    authorize @event
    efforts = @event.efforts.ready_to_start
    response = Interactors::StartEfforts.perform!(efforts, current_user.id)
    set_flash_message(response)
    redirect_to stage_event_path(@event)
  end

# Enable/disable availability for live views

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
    params[:id] = Deprecation::SubstituteSlug.perform(:events, params[:id])
    @event = Event.friendly.find(params[:id])
  end
end
