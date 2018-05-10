class EventGroupsController < ApplicationController
  before_action :authenticate_user!, except: [:index, :show]
  before_action :set_event_group, except: [:index]
  after_action :verify_authorized, except: [:index, :show]

  def index
    scoped_event_groups = EventGroupPolicy::Scope.new(current_user, EventGroup).viewable.search(params[:search])
    @event_groups = EventGroup.where(id: scoped_event_groups.map(&:id))
                        .includes(events: :efforts).includes(:organization)
                        .sort_by { |event_group| -event_group.start_time.to_i }
                        .paginate(page: params[:page], per_page: 25)
    @presenter = EventGroupsCollectionPresenter.new(@event_groups, params, current_user)
    session[:return_to] = event_groups_path
  end

  def show
    events = @event_group.events
    if events.one? && !params[:force_settings]
      redirect_to events.first
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
    if @event_group.events.present?
      flash[:danger] = 'Event group cannot be deleted if events are present within the event group. ' +
          'Delete the related events individually and then delete the event group.'
      redirect_to @event_group
    else
      @event_group.destroy
      flash[:success] = 'Event group deleted.'
      session[:return_to] = params[:referrer_path] if params[:referrer_path]
      redirect_to session.delete(:return_to) || event_groups_path
    end
  end

  def roster
    authorize @event_group

    event_group = EventGroup.where(id: @event_group).includes(events: :efforts).first
    @presenter = EventGroupPresenter.new(event_group, prepared_params, current_user)
  end

  def start_ready_efforts
    authorize @event_group
    efforts = Effort.where(event_id: @event_group.events).ready_to_start
    response = Interactors::StartEfforts.perform!(efforts, current_user.id)
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

  def export_to_summit
    authorize @event_group

    @presenter = EventGroupPresenter.new(@event_group, params, current_user)

    respond_to do |format|
      format.html { redirect_to event_group_path(@event_group, force_settings: true) }
      format.csv do
        csv_stream = render_to_string(partial: 'summit.csv.ruby')
        send_data(csv_stream, type: 'text/csv',
                  filename: "#{@event_group.name}-for-summit-#{Date.today}.csv")
      end
    end
  end

  private

  def set_event_group
    @event_group = EventGroupPolicy::Scope.new(current_user, EventGroup).viewable.friendly.find(params[:id])
    redirect_numeric_to_friendly(@event_group, params[:id])
  end
end
