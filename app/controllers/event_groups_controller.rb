# frozen_string_literal: true

class EventGroupsController < ApplicationController
  before_action :authenticate_user!, except: [:index, :show, :follow, :traffic, :drop_list]
  before_action :set_event_group, except: [:index, :new, :create]
  after_action :verify_authorized, except: [:index, :show, :new, :follow, :traffic, :drop_list, :efforts]

  def index
    scoped_event_groups = policy_scope(EventGroup)
        .search(params[:search])
        .by_group_start_time
        .preload(:events)
        .paginate(page: params[:page], per_page: 25)
    @presenter = EventGroupsCollectionPresenter.new(scoped_event_groups, params, current_user)
    session[:return_to] = event_groups_path
  end

  def show
    event = @event_group.first_event

    if event.present?
      redirect_to spread_event_path(event)
    else
      redirect_to setup_event_group_path(@event_group)
    end
  end

  def new
    organization = Organization.friendly.find(params[:organization_id])

    event_group = organization.event_groups.new
    authorize event_group

    @presenter = ::EventGroupSetupPresenter.new(event_group, view_context)
  end

  def create
    @event_group = EventGroup.new(permitted_params)
    authorize @event_group

    if @event_group.save
      redirect_to setup_event_group_path(@event_group)
    else
      render "new", status: :unprocessable_entity
    end
  end

  def edit
    organization = Organization.friendly.find(params[:organization_id])

    event_group = organization.event_groups.friendly.find(params[:id])
    authorize event_group

    @presenter = ::EventGroupSetupPresenter.new(event_group, view_context)
  end

  def update
    authorize @event_group

    @event_group.update(permitted_params)

    respond_to do |format|
      format.html { redirect_to setup_event_group_path(@event_group) }
      format.turbo_stream { @presenter = EventGroupSetupPresenter.new(@event_group, view_context) }
    end
  end

  def destroy
    authorize @event_group

    @event_group.destroy
    flash[:success] = "Event group deleted."
    redirect_to event_groups_path
  end

  # GET /event_groups/1/setup
  def setup
    authorize @event_group
    @presenter = ::EventGroupSetupPresenter.new(@event_group, view_context)

    respond_to do |format|
      format.html
      format.turbo_stream { render "setup", locals: { presenter: @presenter } }
    end
  end

  # GET /event_groups/1/setup_summary
  def setup_summary
    authorize @event_group
    @presenter = ::EventGroupSetupPresenter.new(@event_group, view_context)

    respond_to do |format|
      format.html
      format.turbo_stream { render "summary", locals: { presenter: @presenter } }
    end
  end

  def efforts
    @efforts = policy_scope(@event_group.efforts)
                 .order(prepared_params[:sort] || :bib_number, :last_name, :first_name)
                 .where(prepared_params[:filter])
                 .finish_info_subquery

    respond_to do |format|
      format.json do
        html = params[:html_template].present? ? render_to_string(partial: params[:html_template], formats: [:html]) : ""
        render json: {efforts: @efforts, html: html}
      end
    end
  end

  def raw_times
    authorize @event_group
    params[:sort] ||= "-created_at"

    event_group = EventGroup.where(id: @event_group).includes(:efforts, organization: :stewards, events: :splits).first
    @presenter = EventGroupRawTimesPresenter.new(event_group, view_context)
  end

  def split_raw_times
    authorize @event_group

    event_group = EventGroup.where(id: @event_group).includes(events: :splits).references(events: :splits).first
    @presenter = SplitRawTimesPresenter.new(event_group, prepared_params, current_user)
  end

  def roster
    authorize @event_group

    event_group = EventGroup.where(id: @event_group).includes(organization: :stewards, events: :splits).first
    @presenter = EventGroupRosterPresenter.new(event_group, view_context)
  end

  def stats
    authorize @event_group

    @presenter = EventGroupStatsPresenter.new(@event_group)
  end

  def drop_list
    event_group = EventGroup.where(id: @event_group).includes(:organization, events: :efforts).first
    @presenter = EventGroupPresenter.new(event_group, prepared_params, current_user)
  end

  def finish_line
    authorize @event_group

    @presenter = EventGroupPresenter.new(@event_group, prepared_params, current_user)
  end

  def follow
    @presenter = EventGroupFollowPresenter.new(@event_group, prepared_params, current_user)

    if @presenter.event_group_finished?
      flash[:success] = "#{@presenter.name} is completed."
      redirect_to event_group_path(@event_group)
    end
  end

  def traffic
    if params[:split_name]
      redirect_to request.params.merge(split_name: nil, parameterized_split_name: params[:split_name]), status: 301
    else
      band_width = params[:band_width].present? ? params.delete(:band_width).to_i : nil
      event_group = EventGroup.where(id: @event_group).includes(events: :splits).references(events: :splits).first
      @presenter = EventGroupTrafficPresenter.new(event_group, prepared_params, band_width)
    end
  end

  # GET /event_groups/1/reconcile
  def reconcile
    authorize @event_group

    event_group = EventGroup.where(id: @event_group.id).includes(efforts: :person).first
    @presenter = ReconcilePresenter.new(event_group, view_context)
  end

  def auto_reconcile
    authorize @event_group

    EffortsAutoReconcileJob.perform_later(@event_group, current_user: current_user)
    flash[:success] = "Automatic reconcile has started. Please return to reconcile after a minute or so."
    redirect_to setup_event_group_path(@event_group)
  end

  def associate_people
    authorize @event_group

    id_hash = params[:ids].to_unsafe_h
    response = Interactors::AssignPeopleToEfforts.perform!(id_hash)
    set_flash_message(response)
    redirect_to reconcile_event_group_path(@event_group)
  end

  def create_people
    authorize @event_group

    response = Interactors::CreatePeopleFromEfforts.perform!(params[:effort_ids])
    set_flash_message(response)
    redirect_to reconcile_event_group_path(@event_group)
  end

  # GET /event_groups/1/link_lotteries
  def link_lotteries
    authorize @event_group

    @presenter = ::EventGroupSetupPresenter.new(@event_group, view_context)
  end

  # GET /event_groups/1/sync_efforts
  def sync_efforts
    authorize @event_group

    @presenter = ::EventGroupSetupPresenter.new(@event_group, view_context)
  end

  # GET /event_groups/1/assign_bibs
  def assign_bibs
    authorize @event_group

    @presenter = ::EventGroupSetupPresenter.new(@event_group, view_context)
  end

  # PATCH /event_groups/1/auto_assign_bibs
  def auto_assign_bibs
    authorize @event_group

    event = @event_group.first_event
    strategy = params[:strategy]
    bib_assignments = ::ComputeBibAssignments.perform(event, strategy)
    response = ::Interactors::BulkSetBibNumbers.perform!(@event_group, bib_assignments)

    set_flash_message(response)
    redirect_to assign_bibs_event_group_path(@event_group)
  end

  # PATCH /event_groups/1/update_bibs
  def update_bibs
    authorize @event_group
    bib_assignments = bib_assignment_hash(params[:event_group])
    response = ::Interactors::BulkSetBibNumbers.perform!(@event_group, bib_assignments)

    if response.successful?
      redirect_to setup_event_group_path(@event_group, display_style: :entrants)
    else
      set_flash_message(response)
      redirect_to assign_bibs_event_group_path(@event_group)
    end
  end

  # GET /event_groups/1/manage_entrant_photos
  def manage_entrant_photos
    authorize @event_group

    @presenter = ::EventGroupSetupPresenter.new(@event_group, view_context)
  end

  # PATCH /event_groups/1/update_entrant_photos
  def update_entrant_photos
    authorize @event_group

    if @event_group.update(permitted_params)
      flash[:success] = "Photos were attached"
    else
      flash[:danger] = "Photos could not be attached: #{@event_group.errors.full_messages}"
    end

    redirect_to manage_entrant_photos_event_group_path(@event_group)
  end

  # PATCH /event_groups/1/assign_entrant_photos
  def assign_entrant_photos
    authorize @event_group

    response = ::Interactors::AssignEntrantPhotos.perform!(@event_group)
    set_flash_message(response)
    redirect_to manage_entrant_photos_event_group_path(@event_group)
  end

  # DELETE /event_groups/1/delete_entrant_photos?entrant_photo_id=1
  def delete_entrant_photos
    authorize @event_group

    @event_group.entrant_photos.find(params[:entrant_photo_id]).purge_later
    redirect_to manage_entrant_photos_event_group_path(@event_group)
  end

  # DELETE /event_groups/1/delete_photos_from_entrants
  def delete_photos_from_entrants
    authorize @event_group

    @event_group.efforts.photo_assigned.find_each do |effort|
      effort.photo.purge_later
    end

    redirect_to manage_entrant_photos_event_group_path(@event_group)
  end

  # GET /event_groups/1/manage_start_times
  def manage_start_times
    authorize @event_group

    @presenter = ::EventGroupSetupPresenter.new(@event_group, view_context)
  end

  # GET /event_groups/1/manage_start_times_edit_actual
  def manage_start_times_edit_actual
    authorize @event_group

    render partial: "form_start_time_actual", locals: {
      event_id: params[:event_id],
      actual_start_time: params[:actual_start_time]&.to_datetime,
    }
  end

  def set_data_status
    authorize @event_group

    @event_group = EventGroup.where(id: @event_group.id).includes(efforts: {split_times: :split}).first
    response = Interactors::UpdateEffortsStatus.perform!(@event_group.efforts)
    set_flash_message(response)
    redirect_to roster_event_group_path(@event_group)
  end

  def start_efforts
    authorize @event_group

    filter = prepared_params[:filter]
    efforts = @event_group.efforts.includes(:event, split_times: :split).roster_subquery
    filtered_efforts = Effort.from(efforts, :efforts).where(filter)
    start_time = params[:actual_start_time]

    start_response = ::Interactors::StartEfforts.perform!(efforts: filtered_efforts, start_time: start_time, current_user_id: current_user.id)

    # Need to pick up the new start split time before setting status
    filtered_efforts = filtered_efforts.includes(split_times: :split)
    set_response = ::Interactors::UpdateEffortsStatus.perform!(filtered_efforts)
    response = start_response.merge(set_response)

    respond_to do |format|
      format.html do
        set_flash_message(response)
        redirect_to request.referrer
      end
      format.json do
        if response.successful?
          render json: {success: true}, status: :created
        else
          render json: {success: false, errors: response.errors}
        end
      end
    end
  end

  def update_all_efforts
    authorize @event_group

    attributes = params.require(:efforts).permit(:checked_in).to_hash
    @event_group.efforts.update_all(attributes)

    redirect_to request.referrer
  end

  def delete_all_efforts
    authorize @event_group

    response = Interactors::BulkDestroyEfforts.perform!(::Effort.where(event: @event_group.events))
    set_flash_message(response) unless response.successful?
    redirect_to setup_event_group_path(@event_group, display_style: :entrants)
  end

  def delete_all_times
    authorize @event_group
    response = Interactors::BulkDeleteEventGroupTimes.perform!(@event_group)
    set_flash_message(response)
    redirect_to setup_event_group_path(@event_group)
  end

  def export_raw_times
    authorize @event_group
    split_name = params[:split_name].to_s.parameterize
    csv_template = params[:csv_template]
    @raw_times = @event_group.raw_times.where(parameterized_split_name: split_name)

    respond_to do |format|
      format.csv do
        csv_stream = render_to_string(partial: csv_template, formats: :csv)
        send_data(csv_stream, type: "text/csv",
                              filename: "#{@event_group.name}-#{split_name}-#{csv_template}-#{Date.today}.csv")
      end
    end
  end

  def delete_duplicate_raw_times
    authorize @event_group

    response = Interactors::DeleteDuplicateRawTimes.perform!(@event_group)
    set_flash_message(response)
    redirect_to raw_times_event_group_path(@event_group)
  end

  private

  def bib_assignment_hash(params_hash)
    params_hash.select { |key, _| key.include?("bib_for") }
               .transform_keys { |key| key.delete("^0-9").to_i }
  end

  def set_event_group
    @event_group = policy_scope(EventGroup).friendly.find(params[:id])
    redirect_numeric_to_friendly(@event_group, params[:id])
  rescue ::ActiveRecord::RecordNotFound
    redirect_to "/404"
  end
end
