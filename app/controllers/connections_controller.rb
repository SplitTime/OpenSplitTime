# frozen_string_literal: true

class ConnectionsController < ApplicationController
  respond_to :turbo_stream

  before_action :authenticate_user!
  before_action :set_destination
  before_action :authorize_organization
  before_action :set_connection, except: [:index, :new, :create]
  after_action :verify_authorized

  def new
    respond_to do |format|
      format.turbo_stream do
        @connection = @destination.connections.new
        set_connection_attributes

        render_destination_new_view
      end
    end
  end

  def create
    head :not_found and return if service.blank?
    head :unprocessable_entity and return if source_type.blank?

    @connection = @destination.connections.new(permitted_params)
    set_connection_attributes
    @connection.save

    render_destination_create_view
  end

  def destroy
    # source_name is passed in as a param because it is not persisted in the database.
    # It is needed to re-render the switch.
    @connection.source_name = source_name
    @connection.destroy
    render_destination_destroy_view
  end

  private

  def authorize_organization
    authorize @destination.organization, policy_class: ::PartnerPolicy
  end

  def render_destination_new_view
    raise NotImplementedError, "render_destination_new_view must be implemented"
  end

  def render_destination_create_view
    raise NotImplementedError, "render_destination_create_view must be implemented"
  end

  def render_destination_destroy_view
    raise NotImplementedError, "render_destination_destroy_view must be implemented"
  end

  def service
    Connectors::Service::BY_IDENTIFIER[service_identifier]
  end

  def service_identifier
    params.dig(:connection, :service_identifier) || @connection.service_identifier
  end

  def set_destination
    raise NotImplementedError, "set_destination must be implemented"
  end

  def set_connection
    @connection = ::Connection.find(params[:id])
  end

  def set_connection_attributes
    @connection.destination = @destination
    @connection.source_type = source_type
  end

  def source_name
    params.dig(:connection, :source_name) || @connection.source_name
  end

  def source_type
    service.resource_map[@destination.class]
  end
end
