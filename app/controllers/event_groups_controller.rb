# frozen_string_literal: true

class EventGroupsController < ApplicationController
  before_action :authenticate_user!, except: [:index, :show, :traffic, :drop_list]
  before_action :set_event_group, except: [:index, :create]
  after_action :verify_authorized, except: [:index, :show, :traffic, :drop_list]

  def index
    scoped_event_groups = EventGroupPolicy::Scope.new(current_user, EventGroup).viewable.search(params[:search])
    @event_groups = EventGroup.distinct
                        .joins(:events) # Excludes "orphaned" event_groups (having no events)
                        .where(id: scoped_event_groups)
                        .includes(:organization, events: :efforts)
                        .sort_by { |event_group| -event_group.start_time.to_i }
                        .paginate(page: params[:page], per_page: 25)
    @presenter = EventGroupsCollectionPresenter.new(@event_groups, params, current_user)
    session[:return_to] = event_groups_path
  end

  def show
    events = @event_group.events
    if events.one? && !params[:force_settings]
      redirect_to spread_event_path(events.first)
    end
    @presenter = EventGroupPresenter.new(@event_group, params, current_user)
  end

  def edit
    authorize @event_group
  end

  def update
    authorize @event_group
    @event_group.assign_attributes(permitted_params)

    if @event_group.concealed_changed?
      setter = EventConcealedSetter.new(event_group: @event_group, concealed: @event_group.concealed)
      setter.perform
      flash[:danger] = setter.response[:errors] unless setter.status == :ok
      redirect_to event_group_path(@event_group, force_settings: true)

    elsif @event_group.save
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

    event_group = EventGroup.where(id: @event_group).includes(organization: :stewards, events: :splits).references(organization: :stewards, events: :splits).first
    @presenter = EventGroupPresenter.new(event_group, prepared_params, current_user)
  end

  def drop_list
    event_group = EventGroup.where(id: @event_group).includes(:organization, events: :efforts).first
    @presenter = EventGroupPresenter.new(event_group, prepared_params, current_user)
  end

  def traffic
    band_width = params[:band_width].present? ? params.delete(:band_width).to_i : nil
    event_group = EventGroup.where(id: @event_group).includes(events: :splits).references(events: :splits).first
    @presenter = EventGroupTrafficPresenter.new(event_group, prepared_params, band_width)
  end

  def set_data_status
    authorize @event_group

    event_group = EventGroup.where(id: @event_group.id).includes(efforts: {split_times: :split}).first
    response = Interactors::UpdateEffortsStatus.perform!(event_group.efforts)
    set_flash_message(response)
    redirect_to roster_event_group_path(@event_group)
  end

  def start_efforts
    authorize @event_group

    filter = prepared_params[:filter]
    efforts = @event_group.efforts.includes(:event, split_times: :split).add_ready_to_start
                  .select { |effort| filter.all? { |method, value| effort.send(method) == value } }
    start_time = params[:start_time]

    response = Interactors::StartEfforts.perform!(efforts: efforts, start_time: start_time, current_user_id: current_user.id)
    set_flash_message(response)
    redirect_to request.referrer
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
    @event_group = EventGroupPolicy::Scope.new(current_user, EventGroup).viewable.friendly.find(params[:id])
    redirect_numeric_to_friendly(@event_group, params[:id])
  end
end
