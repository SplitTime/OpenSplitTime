# frozen_string_literal: true

class StageEventGroupsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_event_group, except: [:new, :create]
  after_action :verify_authorized

  STEPS = %w[your_event event_details courses entrants confirmation published]

  # GET /stage_event_groups/new
  def new
    organization = Organization.find_or_initialize_by(id: params[:organization_id])
    @event_group = EventGroup.new(organization: organization)
    authorize @event_group
    set_presenter

    render current_step
  end

  # GET /stage_event_groups/:id?step=name_of_step
  def edit
    authorize @event_group
    set_presenter

    render current_step
  end

  # POST /stage_event_groups
  def create
    @event_group = EventGroup.new
    authorize @event_group

    if step_updater.update(@event_group, params)
      redirect_to edit_stage_event_group_path(@event_group, {step: step_for_redirect}.merge(redirect_context))
    else
      set_presenter
      render current_step
    end
  end

  # PATCH /stage_event_groups/:id?step=name_of_step
  def update
    authorize @event_group

    if step_updater.update(@event_group, params)
      redirect_to edit_stage_event_group_path(@event_group, {step: step_for_redirect}.merge(redirect_context))
    else
      set_presenter
      render current_step
    end
  end

  private

  def set_event_group
    @event_group = EventGroup.friendly.find(params[:id])
  end

  def set_presenter
    @presenter = step_presenter.new(event_group: @event_group, params: params, current_user: current_user)
  end

  def current_step
    @current_step ||= STEPS.find { |step| step == params[:step].to_s.downcase } || STEPS.first
  end

  def step_for_redirect
    case params[:button]
    when 'Continue'
      STEPS.element_after(current_step) || current_step
    when 'Previous'
      STEPS.element_before(current_step) || current_step
    else
      current_step
    end
  end

  def redirect_context
    context_event_id = params.dig(:event, :id)
    if step_for_redirect.in?(%w(event_details courses)) && context_event_id.present?
      {event: {id: context_event_id}}
    else
      {}
    end
  end

  def step_presenter
    "StageEventGroup::#{current_step.camelcase}Presenter".constantize
  end

  def step_updater
    "StageEventGroup::#{current_step.camelcase}".constantize
  end
end
