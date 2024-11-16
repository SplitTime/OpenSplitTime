# frozen_string_literal: true

class HistoricalFactsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_organization
  before_action :authorize_organization, policy: :historical_fact
  before_action :set_historical_fact, except: [:index, :new, :create]
  after_action :verify_authorized

  def index
    @presenter = ::OrganizationPresenter.new(@organization, view_context)
  end

  def new
    @historical_fact = @organization.historical_facts.new
  end

  def edit
    @historical_fact = @organization.historical_facts.find(params[:id])
  end

  def create
    @historical_fact = @organization.historical_facts.new(permitted_params)

    if @historical_fact.save
      redirect_to :index
    else
      render "new", status: :unprocessable_entity
    end
  end

  def update
    if @historical_fact.update(permitted_params)
      redirect_to :index
    else
      render "edit", status: :unprocessable_entity
    end
  end

  def destroy
    @historical_fact.destroy
    flash[:success] = "Historical fact deleted."
    redirect_to :index
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
