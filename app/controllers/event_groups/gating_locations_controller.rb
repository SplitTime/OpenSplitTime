module EventGroups
  class GatingLocationsController < ApplicationController
    before_action :authenticate_user!
    before_action :set_event_group
    before_action :authorize_event_group
    before_action :set_gating_location, except: [:index, :new, :create]
    after_action :verify_authorized

    def index
      @presenter = ::EventGroupSetupPresenter.new(@event_group, view_context)
    end

    def new
      @gating_location = @event_group.gating_locations.new
      build_missing_gating_location_events
    end

    def edit
      build_missing_gating_location_events
    end

    def create
      @gating_location = @event_group.gating_locations.new(permitted_params)

      if @gating_location.save
        redirect_to gating_locations_path
      else
        build_missing_gating_location_events
        render "new", status: :unprocessable_content
      end
    end

    def update
      if @gating_location.update(permitted_params)
        redirect_to gating_locations_path
      else
        build_missing_gating_location_events
        render "edit", status: :unprocessable_content
      end
    end

    def destroy
      @gating_location.destroy
      flash[:success] = "Gating location deleted."
      redirect_to gating_locations_path
    end

    private

    def authorize_event_group
      authorize @event_group, policy_class: ::GatingLocationPolicy
    end

    def build_missing_gating_location_events
      configured_event_ids = @gating_location.gating_location_events.map(&:event_id)
      @event_group.ordered_events.each do |event|
        @gating_location.gating_location_events.build(event: event) unless event.id.in?(configured_event_ids)
      end
    end

    def gating_locations_path
      organization_event_group_gating_locations_path(@event_group.organization, @event_group)
    end

    # An entry with both aid stations blank means the event is not gated at this
    # location, so a persisted entry is marked for destruction and a new one is dropped.
    def permitted_params
      attrs = params.expect(
        gating_location: [:name,
                          { gating_location_events_attributes: [[:id, :event_id, :gating_aid_station_id,
                                                                 :target_aid_station_id, :default_travel_buffer]] }],
      ).to_h

      attrs["gating_location_events_attributes"]&.each_value do |gle_attrs|
        next if gle_attrs["gating_aid_station_id"].present? || gle_attrs["target_aid_station_id"].present?

        if gle_attrs["id"].present?
          gle_attrs["_destroy"] = true
        else
          gle_attrs.clear
        end
      end

      attrs
    end

    def set_event_group
      @event_group = ::EventGroup.friendly.find(params[:event_group_id])
    end

    def set_gating_location
      @gating_location = @event_group.gating_locations.find(params[:id])
    end
  end
end
