class EffortsController < ApplicationController
  before_action :authenticate_user!, except: [:index, :show, :mini_table, :show_photo, :projections, :analyze, :place, :live_entry_table]
  before_action :set_effort, except: [:index, :new, :create, :create_split_time_from_raw_time, :mini_table]
  after_action :verify_authorized, except: [:index, :show, :mini_table, :show_photo, :projections, :analyze, :place, :live_entry_table]

  # GET /efforts
  def index
    @efforts = policy_scope(Effort).order(prepared_params[:sort] || :bib_number, :last_name, :first_name)
                 .where(prepared_params[:filter])
    respond_to do |format|
      format.html do
        @efforts = @efforts.paginate(page: prepared_params[:page], per_page: prepared_params[:per_page] || 25)
      end
      format.csv do
        builder = CsvBuilder.new(Effort, @efforts)
        filename = if prepared_params[:filter] == { "id" => "0" }
                     "ost-effort-import-template.csv"
                   else
                     "#{prepared_params[:filter].to_param}-#{builder.model_class_name}-#{Time.now.strftime('%Y-%m-%d')}.csv"
                   end

        send_data(builder.full_string, type: "text/csv", filename: filename)
      end
    end
  end

  # GET /efforts/1
  def show
    @presenter = EffortShowView.new(@effort)
    session[:return_to] = effort_path(@effort)
  end

  # GET /efforts/new
  def new
    event = Event.find(params[:event_id])
    effort = event.efforts.new
    authorize effort

    render :new, locals: { effort: effort }
  end

  # GET /efforts/1/edit
  def edit
    authorize @effort
    @effort = Effort.where(id: @effort).includes(event: { event_group: :events }).first

    render :edit, locals: { effort: @effort }
  end

  # POST /efforts
  def create
    effort = Effort.new(permitted_params)
    authorize effort

    if effort.save
      respond_to do |format|
        format.html { redirect_to entrants_event_group_path(effort.event_group) }
        format.turbo_stream do
          render :create, locals: { effort: effort, presenter: EventGroupSetupPresenter.new(effort.event_group, view_context) }
        end
      end
    else
      respond_to do |format|
        format.html { render :new, status: :unprocessable_content }
        format.turbo_stream do
          render turbo_stream: turbo_stream.replace("form_modal", partial: "efforts/new_modal", locals: { effort: effort }), status: :unprocessable_content
        end
      end
    end
  end

  # PATCH/PUT /efforts/1
  def update
    authorize @effort

    respond_to do |format|
      format.html do
        if @effort.update(permitted_params)
          case params[:button]&.to_sym
          when :disassociate
            redirect_to request.referrer
          else
            redirect_to entrants_event_group_path(@effort.event_group)
          end
        else
          render :edit, status: :unprocessable_content
        end
      end

      format.turbo_stream do
        effort = effort_with_splits
        new_event_id = permitted_params.delete(:event_id)&.to_i
        success = effort.update(permitted_params)

        if success && new_event_id && (new_event_id != effort.event_id)
          new_event = effort.event_group.events.find(new_event_id)
          response = Interactors::ChangeEffortEvent.perform!(effort: effort, new_event: new_event)
          success = response.successful?
          effort.errors.add(:event_id, response.error_report) unless success
        end

        if success
          presenter = ::EventGroupRosterPresenter.new(effort.event_group, view_context)
          render :update, locals: { effort: effort, presenter: presenter }
        else
          render turbo_stream: turbo_stream.replace("form_modal", partial: "efforts/edit_modal", locals: { effort: effort }), status: :unprocessable_content
        end
      end
    end
  end

  # DELETE /efforts/1
  def destroy
    authorize @effort

    @effort.destroy
    respond_to do |format|
      format.html { redirect_to entrants_event_group_path(@effort.event_group) }
      format.turbo_stream
    end
  end

  # DELETE /efforts/1/delete_photo
  def delete_photo
    authorize @effort

    @effort.photo.purge_later
    redirect_to manage_entrant_photos_event_group_path(@effort.event_group)
  end

  # GET /efforts/1/projections
  def projections
    @presenter = EffortProjectionsView.new(@effort)

    if params[:modal] == "true"
      render partial: "projections_modal", locals: { presenter: @presenter }
    else
      render "projections", locals: { presenter: @presenter }
    end
  end

  # GET /efforts/1/analyze
  def analyze
    @presenter = EffortAnalysisView.new(@effort)
  end

  # GET /efforts/1/audit
  def audit
    authorize @effort

    @presenter = EffortAuditView.new(@effort)
  end

  # GET /efforts/1/place
  def place
    @presenter = EffortPlaceView.new(@effort)
  end

  # PATCH /efforts/1/rebuild
  def rebuild
    authorize @effort

    effort = Effort.includes(event: :splits).find_by(id: @effort.id)
    response = Interactors::RebuildEffortTimes.perform!(effort: effort)
    set_flash_message(response)

    respond_to do |format|
      format.turbo_stream { @presenter = EffortAuditView.new(effort) }
    end
  end

  # GET /efforts/1/start_form
  def start_form
    authorize @effort
  end

  # PATCH /efforts/1/start
  def start
    authorize @effort

    start_time = params[:actual_start_time]
    response = ::Interactors::StartEfforts.perform!(efforts: [@effort], start_time: start_time)
    set_flash_message(response)
    @effort.reload

    if response.successful?
      respond_to do |format|
        format.turbo_stream { redirect_to effort_path(@effort) }
        format.html { redirect_to effort_path(@effort) }
      end
    else
      respond_to do |format|
        format.turbo_stream { render :start_form, locals: { effort: @effort }, status: :unprocessable_content, alert: response.message }
        format.html { redirect_to effort_path(@effort), status: :unprocessable_content, alert: response.message }
      end
    end
  end

  # PATCH /efforts/1/unstart
  def unstart
    authorize @effort

    response = ::Interactors::UnstartEfforts.perform!([@effort])
    @effort.reload

    respond_to do |format|
      format.turbo_stream do
        if response.successful?
          roster_presenter = ::EventGroupRosterPresenter.new(@effort.event_group, view_context)
          effort_show_view = ::EffortShowView.new(@effort)
          render :unstart, locals: { effort_presenter: effort_show_view, roster_presenter: roster_presenter }
        else
          redirect_to effort_path(@effort), status: :unprocessable_content
        end
      end
    end
  end

  # PATCH /efforts/1/stop
  def stop
    authorize @effort
    effort = effort_with_splits
    stop_status = params[:status]&.to_boolean

    stop_response = Interactors::UpdateEffortsStop.perform!(effort, stop_status: stop_status)
    update_response = Interactors::UpdateEffortsStatus.perform!(effort)
    set_flash_message(stop_response.merge(update_response))
    redirect_to effort_path(effort)
  end

  # PATCH /efforts/1/smart_stop
  def smart_stop
    authorize @effort
    effort = effort_with_splits

    response = Interactors::SmartUpdateEffortStop.perform!(effort)
    set_flash_message(response)
    redirect_to effort_path(effort)
  end

  # POST /efforts/1/create_split_time_from_raw_time
  def create_split_time_from_raw_time
    @effort = policy_scope(Effort).friendly.find(params[:id])
    authorize @effort

    raw_time = RawTime.find(params[:raw_time_id])
    split_time = ::SplitTimeFromRawTime.build(raw_time, effort: @effort, event: @effort.event, lap: params[:lap])

    if split_time.save
      raw_time.update(split_time: split_time)
      Interactors::UpdateEffortsStatus.perform!(@effort.reload)
      redirect_to audit_effort_path(@effort)
    else
      flash[:danger] = "Raw time could not be matched:\n#{split_time.errors.full_messages.join("\n")}"
      @presenter = EffortAuditView.new(@effort)
      render "efforts/audit"
    end
  end

  # GET /efforts/1/edit_split_times
  def edit_split_times
    authorize @effort
    effort = Effort.where(id: @effort.id).includes(:event, split_times: :split).first

    @presenter = EffortWithTimesPresenter.new(effort, params: params)
  end

  # PATCH /efforts/1/update_split_times
  def update_split_times
    authorize @effort
    effort = effort_with_splits

    if effort.update(permitted_params)
      status_response = Interactors::UpdateEffortsStatus.perform!(effort)
      set_flash_message(status_response)

      redirect_to effort_path(effort)
    else
      @presenter = EffortWithTimesPresenter.new(effort, params: params)
      render :edit_split_times, display_style: params[:display_style], status: :unprocessable_content
    end
  end

  # DELETE /efforts/1/delete_split_times
  def delete_split_times
    authorize @effort
    effort = Effort.where(id: @effort.id).includes(split_times: { split: :course }).first

    destroy_response = Interactors::DestroyEffortSplitTimes.perform!(effort, params[:split_time_ids])
    update_response = Interactors::UpdateEffortsStatus.perform!(effort)
    set_flash_message(destroy_response.merge(update_response))
    redirect_to effort_path(effort)
  end

  # PATCH /efforts/1/set_data_status
  def set_data_status
    authorize @effort
    Interactors::UpdateEffortsStatus.perform!(@effort)
    redirect_to effort_path(@effort)
  end

  # This action uses POST because a GET may exceed the maximum length of a URL.
  # POST /efforts/mini_table
  def mini_table
    if params[:effort_ids].present? && params[:target].present?
      mini_table = EffortsMiniTable.new(params[:effort_ids])
      render turbo_stream: turbo_stream.update(params[:target], partial: "efforts/efforts_mini_table", locals: { effort_rows: mini_table.effort_rows })
    else
      head :unprocessable_content
    end
  end

  # GET /efforts/1/live_entry_table
  def live_entry_table
    respond_to do |format|
      format.turbo_stream do
        effort = Effort.where(id: @effort).includes(event: :splits, split_times: :split).first
        effort.ordered_split_times.each_cons(2) do |begin_st, end_st|
          end_st.segment_time ||= end_st.absolute_time - begin_st.absolute_time
        end
        presenter = EffortWithTimesRowPresenter.new(effort)
        render "efforts/live_entry_table", locals: { presenter: presenter }
      end
    end
  end

  # GET /efforts/1/show_photo
  def show_photo
    render partial: "show_photo"
  end

  private

  def effort_with_splits
    Effort.where(id: @effort.id).includes(split_times: :split).first
  end

  def set_effort
    @effort = policy_scope(Effort).friendly.find(params[:id])
    redirect_numeric_to_friendly(@effort, params[:id]) if request.format.html?
  end
end
