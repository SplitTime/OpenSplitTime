class EffortsController < ApplicationController
  before_action :authenticate_user!, except: [:index, :show, :mini_table, :show_photo, :subregion_options, :analyze, :place]
  before_action :set_effort, except: [:index, :new, :create, :associate_participants, :mini_table, :subregion_options]
  after_action :verify_authorized, except: [:index, :show, :mini_table, :show_photo, :subregion_options, :analyze, :place]

  before_action do
    locale = params[:locale]
    Carmen.i18n_backend.locale = locale if locale
  end

  def index

  end

  def show
    @effort_show = EffortShowView.new(effort: @effort)
    session[:return_to] = effort_path(@effort)
  end

  def new
    @effort = Effort.new
    if params[:event_id]
      @event = Event.friendly.find(params[:event_id])
      @effort.event = @event
    end
    authorize @effort
  end

  def edit
    @event = Event.friendly.find(@effort.event_id)
    authorize @effort
  end

  def create
    @effort = Effort.new(permitted_params)
    authorize @effort

    if @effort.save
      redirect_to stage_event_path(@effort.event)
    else
      render 'new'
    end
  end

  def update
    authorize @effort

    if @effort.update(permitted_params)
      redirect_to stage_event_path(@effort.event)
    else
      render 'edit'
    end
  end

  def destroy
    authorize @effort
    @effort.destroy
    session[:return_to] = params[:referrer_path] if params[:referrer_path]
    redirect_to session.delete(:return_to) || root_path
  end

  def analyze
    @effort_analysis = EffortAnalysisView.new(@effort)
    session[:return_to] = analyze_effort_path(@effort)
  end

  def place
    @effort_place = PlaceDetailView.new(@effort)
    session[:return_to] = place_effort_path(@effort)
  end

  def associate_participants
    @event = Event.friendly.find(params[:event_id])
    authorize @event
    id_hash = params[:ids].to_unsafe_h

    if id_hash.blank?
      redirect_to reconcile_event_path(@event)
    else
      count = EventReconcileService.assign_participants_to_efforts(id_hash)
      flash[:success] = "#{count.to_s + ' effort'.pluralize(count)} reconciled." if count > 0
      redirect_to reconcile_event_path(@event)
    end
  end

  def start
    authorize @effort
    BulkUpdateService.start_efforts([@effort], @current_user.id)
    redirect_to effort_path(@effort)
  end

  def edit_split_times
    authorize @effort
    effort_with_relations = Effort.where(id: @effort.id).eager_load(:event, :split_times).first
    @presenter = EffortWithTimesPresenter.new(effort: effort_with_relations, params: params)
  end

  def update_split_times
    authorize @effort
    if @effort.update(permitted_params)
      @effort.set_data_status
      redirect_to effort_path(@effort)
    else
      flash[:danger] = "Effort failed to update for the following reasons: #{@effort.errors.full_messages}"
      render 'edit_split_times'
    end
  end

  def delete_split_times
    authorize @effort
    @effort.destroy_split_times(params[:split_time_ids])
    redirect_to effort_path(@effort)
  end

  def confirm_split_times
    authorize @effort
    split_times = @effort.split_times.where(id: params[:split_time_ids])
    if params[:status] == 'confirmed'
      split_times.confirmed!
    else
      split_times.good!
    end
    @effort.set_data_status
    redirect_to effort_path(@effort)
  end

  def set_data_status
    authorize @effort
    @effort.set_data_status
    redirect_to effort_path(@effort)
  end

  def mini_table
    @mini_table = EffortsMiniTable.new(params[:effort_ids])
    render partial: 'efforts_mini_table'
  end

  def show_photo
    render partial: 'show_photo'
  end

  def add_beacon
    authorize(@effort)
    update_beacon_url(params[:value])
    respond_to do |format|
      format.html { redirect_to effort_path(@effort) }
      format.js { render inline: "location.reload();" }
    end
  end

  def add_report
    authorize(@effort)
    update_report_url(params[:value])
    respond_to do |format|
      format.html { redirect_to effort_path(@effort) }
      format.js { render inline: "location.reload();" }
    end
  end

  def add_photo
    authorize @effort
    file_url = FileStore.public_upload("effort-photos/#{@effort.event_name}", params[:file], @effort.id)
    @effort.update(photo_url: file_url) if file_url
    redirect_to effort_path(@effort)
  end

  def subregion_options
    render partial: 'subregion_select'
  end

  private

  def set_effort
    @effort = Effort.friendly.find(params[:id])
  end

  def update_beacon_url(url)
    @effort.update(beacon_url: url)
  end

  def update_report_url(url)
    @effort.update(report_url: url)
  end
end
