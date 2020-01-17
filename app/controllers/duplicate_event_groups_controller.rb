# frozen_string_literal: true

class DuplicateEventGroupsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_existing_event_group
  after_action :verify_authorized

  def new
    authorize @existing_event_group, policy_class: DuplicateEventGroupPolicy
    @duplicate_event_group = DuplicateEventGroup.new(existing_id: @existing_event_group.id, new_start_date: Date.today)
  end

  def create
    authorize @existing_event_group, policy_class: DuplicateEventGroupPolicy
    @duplicate_event_group = DuplicateEventGroup.create(permitted_params)

    if @duplicate_event_group.valid?
      redirect_to event_group_path(@duplicate_event_group.new_event_group, force_settings: true)
    else
      render 'new'
    end
  end

  private

  def set_existing_event_group
    existing_id = params[:existing_id] || params.dig(:duplicate_event_group, :existing_id)
    @existing_event_group = EventGroup.friendly.find(existing_id)
  end
end
