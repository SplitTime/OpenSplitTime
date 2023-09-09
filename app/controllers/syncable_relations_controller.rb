# frozen_string_literal: true

class SyncableRelationsController < ApplicationController
  respond_to :turbo_stream

  before_action :authenticate_user!
  before_action :set_syncable
  before_action :authorize_organization
  before_action :set_syncable_source, except: [:new, :create]
  after_action :verify_authorized

  def new
    respond_to do |format|
      format.turbo_stream do
        @syncable_source = @syncable.syncable_sources.new
        set_syncable_source_attributes

        render_syncable_new_view
      end
    end
  end

  def create
    head :route_not_found and return if service.blank?
    head :unprocessable_entity and return if source_type.blank?

    @syncable_source = @syncable.syncable_sources.new(permitted_params)
    set_syncable_source_attributes
    @syncable_source.save

    render_syncable_create_view
  end

  def destroy
    @syncable_source.destroy
    render_syncable_destroy_view
  end

  private

  def source_type
    service.resource_map[@syncable.class]
  end

  def authorize_organization
    authorize @syncable.organization, policy_class: ::PartnerPolicy
  end

  def render_syncable_new_view
    raise NotImplementedError, "render_syncable_new_view must be implemented"
  end

  def render_syncable_create_view
    raise NotImplementedError, "render_syncable_create_view must be implemented"
  end

  def render_syncable_destroy_view
    raise NotImplementedError, "render_syncable_destroy_view must be implemented"
  end

  def service
    Connectors::Service::BY_IDENTIFIER[service_identifier]
  end

  def service_identifier
    params.dig(:syncable_relation, :source_name)
  end

  def set_syncable
    raise NotImplementedError, "set_syncable must be implemented"
  end

  def set_syncable_source
    @syncable_source = ::SyncableRelation.where(destination_name: "internal", destination_type: @syncable.class.name, destination_id: @syncable.id)
                                           .find(params[:id])
  end

  def set_syncable_source_attributes
    @syncable_source.destination_name = "internal"
    @syncable_source.destination_type = @syncable.class.name
    @syncable_source.destination_id = @syncable.id
    @syncable_source.source_type = source_type
  end
end
