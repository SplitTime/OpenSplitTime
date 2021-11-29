# frozen_string_literal: true

class EventGroupsController < ApplicationController
  before_action :authenticate_user!, except: [:index, :show, :follow, :traffic, :drop_list]
  before_action :set_event_group, except: [:index, :create]
  after_action :verify_authorized, except: [:index, :show, :follow, :traffic, :drop_list, :efforts]

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
    events = @event_group.events
    if events.one? && !params[:force_settings]
      redirect_to spread_event_path(events.first)
    end
    @presenter = EventGroupPresenter.new(@event_group, params, current_user)
    session[:return_to] = event_group_path(@event_group, force_settings: true)
  end

  def edit
    authorize @event_group
  end

  def update
    authorize @event_group

    if @event_group.update(permitted_params)
      redirect_to event_group_path(@event_group, force_settings: true)
    else
      render 'edit'
    end
  end

  def destroy
    authorize @event_group

    @event_group.destroy
    flash[:success] = 'Event group deleted.'
    redirect_to event_groups_path
  end

  def efforts
    @efforts = policy_scope(@event_group.efforts)
                 .order(prepared_params[:sort] || :bib_number, :last_name, :first_name)
                 .where(prepared_params[:filter])

    respond_to do |format|
      format.json do
        html = params[:html_template].present? ? render_to_string(partial: params[:html_template], formats: [:html]) : ""
        render json: {efforts: @efforts, html: html}
      end
    end
  end

  def raw_times
    authorize @event_group
    params[:sort] ||= '-created_at'

    event_group = EventGroup.where(id: @event_group).includes(:efforts, organization: :stewards, events: :splits).first
    @presenter = EventGroupRawTimesPresenter.new(event_group, prepared_params, current_user)
  end

  def split_raw_times
    authorize @event_group

    event_group = EventGroup.where(id: @event_group).includes(events: :splits).references(events: :splits).first
    @presenter = SplitRawTimesPresenter.new(event_group, prepared_params, current_user)
  end

  def roster
    authorize @event_group

    event_group = EventGroup.where(id: @event_group).includes(organization: :stewards, events: :splits).first
    @presenter = EventGroupRosterPresenter.new(event_group, prepared_params, current_user)
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

  def reconcile
    authorize @event_group

    event_group = EventGroup.where(id: @event_group.id).includes(efforts: :person).first
    @presenter = ReconcilePresenter.new(parent: event_group, params: prepared_params, current_user: current_user)
  end

  def auto_reconcile
    authorize @event_group

    EffortsAutoReconcileJob.perform_later(@event_group, current_user: current_user)
    flash[:success] = 'Automatic reconcile has started. Please return to reconcile after a minute or so.'
    redirect_to event_group_path(@event_group, force_settings: true)
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

  def set_data_status
    authorize @event_group

    @event_group = EventGroup.where(id: @event_group.id).includes(efforts: { split_times: :split }).first
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
          render json: { success: true }, status: :created
        else
          render json: { success: false, errors: response.errors }
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

  def delete_all_times
    authorize @event_group
    response = Interactors::BulkDeleteEventGroupTimes.perform!(@event_group)
    set_flash_message(response)
    redirect_to event_group_path(@event_group, force_settings: true)
  end

  def export_raw_times
    authorize @event_group
    split_name = params[:split_name].to_s.parameterize
    csv_template = params[:csv_template]
    @raw_times = @event_group.raw_times.where(parameterized_split_name: split_name)

    respond_to do |format|
      format.csv do
        csv_stream = render_to_string(partial: "#{csv_template}.csv.ruby")
        send_data(csv_stream, type: 'text/csv',
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

  def set_event_group
    @event_group = policy_scope(EventGroup).friendly.find(params[:id])
    redirect_numeric_to_friendly(@event_group, params[:id])
  end
end
