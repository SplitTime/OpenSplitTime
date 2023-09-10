# frozen_string_literal: true

class Connectors::ServicesController < ApplicationController
  respond_to :turbo_stream

  before_action :authenticate_user!
  before_action :set_connectable
  before_action :authorize_organization
  before_action :set_service
  after_action :verify_authorized

  private

  def authorize_organization
    authorize @connectable.organization, policy_class: ::Connectors::ServicePolicy
  end

  def service_identifier
    params[:service_identifier]
  end

  def set_connectable
    raise NotImplementedError, "set_connectable must be implemented"
  end

  def set_service
    @service = Connectors::Service::BY_IDENTIFIER[service_identifier]

    raise ActionController::RoutingError, "Not Found" if @service.blank?
  end
end
