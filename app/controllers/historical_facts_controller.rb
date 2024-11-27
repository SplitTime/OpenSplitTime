# frozen_string_literal: true

class HistoricalFactsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_organization
  before_action :authorize_organization, policy: :historical_fact
  before_action :set_historical_fact, only: %i[edit update destroy]
  after_action :verify_authorized

  # GET /organizations/1/historical_facts
  def index
    @presenter = ::OrganizationHistoricalFactsPresenter.new(@organization, view_context)
  end

  # GET /organizations/1/historical_facts/new
  def new
    @historical_fact = @organization.historical_facts.new
  end

  # GET /organizations/1/historical_facts/1/edit
  def edit
    @historical_fact = @organization.historical_facts.find(params[:id])
  end

  # POST /organizations/1/historical_facts/create
  def create
    @historical_fact = @organization.historical_facts.new(permitted_params)

    if @historical_fact.save
      redirect_to :index
    else
      render "new", status: :unprocessable_entity
    end
  end

  # PATCH /organizations/1/historical_facts/1/update
  def update
    if @historical_fact.update(permitted_params)
      redirect_to :index
    else
      render "edit", status: :unprocessable_entity
    end
  end

  # DELETE /organizations/1/historical_facts/1/destroy
  def destroy
    @historical_fact.destroy
  end

  # PATCH /organizations/1/historical_facts/auto_reconcile
  def auto_reconcile
    HistoricalFactsAutoReconcileJob.perform_later(@organization, current_user: current_user)
    flash[:success] = "Auto reconcile has started."
  end

  # PATCH /organizations/1/historical_facts/match?personal_info_hash=abc123&person_id=1&redirect_hash=abc123
  def match
    redirect_hash = params[:redirect_hash]
    personal_info_hash = params[:personal_info_hash]
    person_id = params[:person_id]
    person = person_id == "new" ? Person.new : Person.find(person_id)

    if personal_info_hash.present? && person.present?
      HistoricalFactsReconcileJob.perform_later(
        @organization,
        current_user: current_user,
        personal_info_hash: personal_info_hash,
        person_id: person_id,
      )

      if redirect_hash.present?
        redirect_to reconcile_organization_historical_facts_path(@organization, personal_info_hash: redirect_hash), flash: { success: "Matching facts with #{person.full_name.presence || 'new Person'}" }
      else
        redirect_to organization_historical_facts_path(@organization), flash: { warning: "Nothing to reconcile." }
      end
    else
      redirect_to reconcile_organization_historical_facts_path(@organization), flash: { danger: "Unable to match person_id: #{person_id || '[missing]'} and personal_info_hash: #{personal_info_hash || '[missing'}" }
    end
  end

  # GET /organizations/1/historical_facts/reconcile?personal_info_hash=abc123
  def reconcile
    params[:personal_info_hash] ||= @organization.historical_facts.unreconciled.order(:id).first&.personal_info_hash
    @presenter = OrganizationHistoricalFactsReconcilePresenter.new(@organization, view_context)
  end

  private

  def set_organization
    @organization = Organization.friendly.find(params[:organization_id])
  end

  def authorize_organization
    authorize @organization, policy_class: ::HistoricalFactPolicy
  end

  def set_historical_fact
    @historical_fact = @organization.historical_facts.find(params[:id])
  end
end
