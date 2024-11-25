# frozen_string_literal: true

class HistoricalFactsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_organization
  before_action :authorize_organization, policy: :historical_fact
  before_action :set_historical_fact, except: [:index, :new, :create, :auto_reconcile, :reconcile]
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
    flash[:success] = "Historical fact deleted."
    redirect_to :index
  end

  # PATCH /organizations/1/historical_facts/auto_reconcile
  def auto_reconcile
    HistoricalFactsAutoReconcileJob.perform_later(@organization, current_user: current_user)
    flash[:success] = "Auto reconcile has started."
  end

  # GET /organizations/1/historical_facts/reconcile
  def reconcile
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
