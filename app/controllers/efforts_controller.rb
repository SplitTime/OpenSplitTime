class EffortsController < ApplicationController
  before_action :authenticate_user!, except: [:index, :show, :mini_table, :show_photo, :subregion_options, :projections, :analyze, :place]
  before_action :set_effort, except: [:index, :new, :create, :create_split_time_from_raw_time, :associate_people, :mini_table, :subregion_options]
  after_action :verify_authorized, except: [:index, :show, :mini_table, :show_photo, :subregion_options, :projections, :analyze, :place]

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

  def show
    @presenter = EffortShowView.new(@effort)
    session[:return_to] = effort_path(@effort)
  end

  def new
    event = Event.find(params[:event_id])
    @effort = event.efforts.new
    authorize @effort
  end

  def edit
    authorize @effort
    @effort = Effort.where(id: @effort).includes(event: { event_group: :events }).first
  end

  def create
    @effort = Effort.new(permitted_params)
    authorize @effort

    if @effort.save
      respond_to do |format|
        format.html { redirect_to entrants_event_group_path(@effort.event_group) }
        format.turbo_stream { @presenter = EventGroupSetupPresenter.new(@effort.event_group, view_context) }
      end
    else
      render "new", status: :unprocessable_entity
    end
  end

  def update
    authorize @effort

    respond_to do |format|
      format.html do
        effort = effort_with_splits
        new_event_id = permitted_params.delete(:event_id)&.to_i

        if effort.update(permitted_params)
          case params[:button]&.to_sym
          when :disassociate
            redirect_to request.referrer
          else
            redirect_to entrants_event_group_path(effort.event_group)
          end

          if new_event_id && new_event_id != effort.event_id
            new_event = Event.find(new_event_id)
            response = Interactors::ChangeEffortEvent.perform!(effort: effort, new_event: new_event)
            set_flash_message(response)
          end
        else
          @effort = effort
          render :edit, status: :unprocessable_entity
        end
      end

      format.turbo_stream do
        if @effort.update(permitted_params)
          presenter = ::EventGroupRosterPresenter.new(@effort.event_group, view_context)
          render :update, locals: { effort: @effort, presenter: presenter }
        else
          render :update, locals: { effort: @effort, presenter: presenter }, status: :unprocessable_entity
        end
      end
    end
  end

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

  def projections
    @presenter = EffortProjectionsView.new(@effort)

    if params[:modal] == "true"
      render partial: "projections_modal", locals: { presenter: @presenter }
    else
      render "projections", locals: { presenter: @presenter }
    end
  end

  def analyze
    @presenter = EffortAnalysisView.new(@effort)
  end

  def audit
    authorize @effort

    @presenter = EffortAuditView.new(@effort)
  end

  def place
    @presenter = EffortPlaceView.new(@effort)
  end

  def rebuild
    authorize @effort

    effort = Effort.where(id: @effort.id).includes(event: :splits).first
    response = Interactors::RebuildEffortTimes.perform!(effort: effort, current_user_id: current_user.id)
    set_flash_message(response) unless response.successful?
    redirect_to request.referrer || audit_effort_path(effort)
  end

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
          redirect_to effort_path(@effort), status: :unprocessable_entity
        end
      end
    end
  end

  def stop
    authorize @effort
    effort = effort_with_splits
    stop_status = params[:status]&.to_boolean

    stop_response = Interactors::UpdateEffortsStop.perform!(effort, stop_status: stop_status)
    update_response = Interactors::UpdateEffortsStatus.perform!(effort)
    set_flash_message(stop_response.merge(update_response))
    redirect_to effort_path(effort)
  end

  def smart_stop
    authorize @effort
    effort = effort_with_splits

    response = Interactors::SmartUpdateEffortStop.perform!(effort)
    set_flash_message(response)
    redirect_to effort_path(effort)
  end

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

  def edit_split_times
    authorize @effort
    effort = Effort.where(id: @effort.id).includes(:event, split_times: :split).first

    @presenter = EffortWithTimesPresenter.new(effort, params: params)
  end

  def update_split_times
    authorize @effort
    effort = effort_with_splits

    if effort.update(permitted_params)
      status_response = Interactors::UpdateEffortsStatus.perform!(effort)
      set_flash_message(status_response)

      redirect_to effort_path(effort)
    else
      flash[:danger] = "Effort failed to update for the following reasons: #{effort.errors.full_messages}"
      @presenter = EffortWithTimesPresenter.new(effort, params: params)
      render "edit_split_times", display_style: params[:display_style]
    end
  end

  def delete_split_times
    authorize @effort
    effort = Effort.where(id: @effort.id).includes(split_times: { split: :course }).first

    destroy_response = Interactors::DestroyEffortSplitTimes.perform!(effort, params[:split_time_ids])
    update_response = Interactors::UpdateEffortsStatus.perform!(effort)
    set_flash_message(destroy_response.merge(update_response))
    redirect_to effort_path(effort)
  end

  def set_data_status
    authorize @effort
    Interactors::UpdateEffortsStatus.perform!(@effort)
    redirect_to effort_path(@effort)
  end

  def mini_table
    if params[:effort_ids].present?
      @mini_table = EffortsMiniTable.new(params[:effort_ids])
      render partial: "efforts_mini_table"
    else
      render html: "No effort ids provided", status: :unprocessable_entity
    end
  end

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
