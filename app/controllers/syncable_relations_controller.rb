# frozen_string_literal: true

class SyncableRelationsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_syncable
  before_action :authorize_organization
  before_action :set_syncable_relation, except: [:create]
  after_action :verify_authorized

  def create
    @syncable_relation = ::SyncableRelation.new(permitted_params)
    @syncable_relation.destination_name = "internal"
    @syncable_relation.destination_type = @syncable.class.name
    @syncable_relation.destination_id = @syncable.id

    if @syncable_relation.save!
      render_syncable_view
    else
      flash[:warning] = "Relation could not be saved: #{@syncable_relation.errors.full_messages}"
      # Do something
    end
  end

  def destroy
    @syncable_relation.destroy
    render_syncable_view
  end

  private

  def authorize_organization
    authorize @syncable.organization, policy_class: ::PartnerPolicy
  end

  def render_syncable_view
    raise NotImplementedError, "render_syncable_view must be implemented"
  end

  def set_syncable
    raise NotImplementedError, "set_syncable must be implemented"
  end

  def set_syncable_relation
    @syncable_relation = ::SyncableRelation.where(destination_name: "internal", destination_type: @syncable.class.name, destination_id: @syncable.id)
                                           .find(params[:id])
  end
end
