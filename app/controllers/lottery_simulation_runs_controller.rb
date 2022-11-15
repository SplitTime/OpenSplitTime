# frozen_string_literal: true

class LotterySimulationRunsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_organization
  before_action :authorize_organization
  before_action :set_lottery
  before_action :set_lottery_simulation_run, only: [:show, :destroy]
  after_action :verify_authorized

  # GET /organizations/:organization_id/lotteries/:lottery_id/lottery_simulation_runs
  def index
  end

  # GET /organizations/:organization_id/lotteries/:lottery_id/lottery_simulation_runs/:id
  def show
  end

  # GET /organizations/:organization_id/lotteries/:lottery_id/lottery_simulation_runs/new
  def new
    @lottery_simulation_run = @lottery.simulation_runs.new
  end

  # POST /organizations/:organization_id/lotteries/:lottery_id/lottery_simulation_runs
  def create
    @lottery_simulation_run = @lottery.simulation_runs.new(permitted_params)
    @lottery_simulation_run.status = :waiting

    if @lottery_simulation_run.save
      ::LotterySimulations::RunnerJob.perform_later(@lottery_simulation_run.id)
      flash[:success] = "Simulation run in progress."
      redirect_to organization_lottery_lottery_simulation_runs_path(@organization, @lottery)
    else
      render "new", status: :unprocessable_entity
    end
  end

  # DELETE /organizations/:organization_id/lotteries/:lottery_id/lottery_simulation_runs/:id
  def destroy
    unless @lottery_simulation_run.destroy
      flash[:danger] = "Unable to delete simulation run: #{@lottery_simulation_run.errors.full_messages.join(', ')}"
    end

    redirect_to organization_lottery_lottery_simulation_runs_path(@organization, @lottery)
  end

  private

  def authorize_organization
    authorize @organization, policy_class: ::LotterySimulationRunPolicy
  end

  def set_lottery
    @lottery = policy_scope(@organization.lotteries).friendly.find(params[:lottery_id])
  end

  def set_lottery_simulation_run
    @lottery_simulation_run = @lottery.simulation_runs.find(params[:id])
  end

  def set_organization
    @organization = policy_scope(::Organization).friendly.find(params[:organization_id])
  end
end
