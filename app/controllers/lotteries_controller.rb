# frozen_string_literal: true

class LotteriesController < ApplicationController
  before_action :authenticate_user!, except: [:index, :show, :best_efforts, :plan_effort]
  before_action :set_organization
  before_action :set_lottery, except: [:index, :new, :create]
  after_action :verify_authorized, except: [:index, :show, :best_efforts, :plan_effort]

  def index
    params[:display_style] = "lotteries"
    @presenter = OrganizationPresenter.new(@organization, prepared_params, current_user)

    render "organizations/show"
  end

  def show
    @presenter = LotteryPresenter.new(@lottery, view_context)
  end

  def new
    @lottery = @organization.lotteries.new
    authorize @lottery
  end

  def edit
    authorize @lottery
  end

  def create
    @lottery = @organization.lotteries.new(permitted_params)
    authorize @lottery

    if @lottery.save
      redirect_to admin_organization_lottery_path(@organization, @lottery)
    else
      render "new"
    end
  end

  def update
    authorize @lottery

    if @lottery.update(permitted_params)
      redirect_to admin_organization_lottery_path(@organization, @lottery), notice: "Lottery updated"
    else
      render "edit"
    end
  end

  def destroy
    authorize @lottery

    if @lottery.destroy
      flash[:success] = "Lottery deleted."
      redirect_to organization_lotteries_path
    else
      flash[:danger] = @lottery.errors.full_messages.join("\n")
      redirect_to organization_lottery_path(@organization, @lottery)
    end
  end

  def admin
    authorize @lottery
    @presenter = LotteryPresenter.new(@lottery, view_context)
  end

  def draw
    authorize @lottery

    division = @lottery.divisions.find(params[:division_id])
    ticket = division.draw_ticket!

    if ticket.present?
      head :created
    else
      head :no_content
    end
  end

  private

  def set_lottery
    @lottery = policy_scope(Lottery).friendly.find(params[:lottery_id])
  end

  def set_organization
    @organization = policy_scope(Organization).friendly.find(params[:organization_id])
  end
end
