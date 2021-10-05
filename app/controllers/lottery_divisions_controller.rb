# frozen_string_literal: true

class LotteryDivisionsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_organization
  before_action :set_lottery
  before_action :set_lottery_division, except: [:new, :create]
  after_action :verify_authorized

  def new
    @lottery_division = @lottery.divisions.new
    authorize @lottery_division
  end

  def edit
    authorize @lottery
  end

  def create
    @lottery_division = @lottery.divisions.new(permitted_params)
    authorize @lottery_division

    if @lottery_division.save
      redirect_to setup_organization_lottery_path(@organization, @lottery)
    else
      render "new"
    end
  end

  def update
    authorize @lottery_division

    if @lottery_division.update(permitted_params)
      redirect_to setup_organization_lottery_path(@organization, @lottery)
    else
      render "edit"
    end
  end

  def destroy
    authorize @lottery_division

    if @lottery_division.destroy
      redirect_to setup_organization_lottery_path(@organization, @lottery)
    else
      flash[:danger] = @lottery.errors.full_messages.join("\n")
      redirect_to setup_organization_lottery_path(@organization, @lottery)
    end
  end

  private

  def set_lottery
    @lottery = policy_scope(@organization.lotteries).friendly.find(params[:lottery_id])
  end

  def set_lottery_division
    @lottery_division = policy_scope(@lottery.divisions).find(params[:id])
  end

  def set_organization
    @organization = policy_scope(Organization).friendly.find(params[:organization_id])
  end
end
