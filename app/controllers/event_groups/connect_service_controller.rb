# frozen_string_literal: true

module EventGroups
  class ConnectServiceController < ApplicationController
    before_action :authenticate_user!
    before_action :set_event_group
    before_action :set_service

    def show
      head :route_not_found and return if @service.blank?

      render "event_groups/connect_service/show",
             locals: {
               event_group_setup_presenter: EventGroupSetupPresenter.new(@event_group, view_context),
               connect_service_presenter: ConnectServicePresenter.new(@event_group, @service, view_context),
             }
    end

    def connect_new
      render :connect_new, locals: { event_group: @event_group, service_identifier: @service&.identifier }
    end

    private

    def set_event_group
      @event_group = EventGroup.friendly.find(params[:event_group_id])
    end

    def set_service
      @service = Connectors::Service::BY_IDENTIFIER[params[:id]]
    end
  end
end
