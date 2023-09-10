# frozen_string_literal: true

module EventGroups
  class ConnectServiceController < ApplicationController
    before_action :authenticate_user!
    before_action :set_event_group
    before_action :set_service

    def show
      render "event_groups/connect_service/show",
             locals: {
               event_group_setup_presenter: EventGroupSetupPresenter.new(@event_group, view_context),
               connect_service_presenter: ConnectServicePresenter.new(@event_group, @service, view_context),
             }
    end

    private

    def set_event_group
      @event_group = EventGroup.friendly.find(params[:event_group_id])
    end

    def set_service
      @service = Connectors::Service::BY_IDENTIFIER[params[:id]]
      raise ActiveRecord::RecordNotFound if @service.blank?
    end
  end
end
