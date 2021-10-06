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
      redirect_to setup_organization_lottery_path(@organization, @lottery)
    else
      render "new"
    end
  end

  def update
    authorize @lottery

    if @lottery.update(permitted_params)
      redirect_to setup_organization_lottery_path(@organization, @lottery), notice: "Lottery updated"
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

  def draw_tickets
    authorize @lottery
    @presenter = LotteryPresenter.new(@lottery, view_context)
  end

  def setup
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

  def delete_tickets
    authorize @lottery

    if @lottery.draws.delete_all && @lottery.tickets.delete_all
      flash[:success] = "Deleted all lottery tickets and draws"
    else
      flash[:danger] = "Unable to delete all lottery tickets and draws"
    end

    redirect_to setup_organization_lottery_path(@organization, @lottery)
  end

  def generate_tickets
    authorize @lottery

    if @lottery.delete_and_insert_tickets!
      flash[:success] = "Generated lottery tickets"
    else
      flash[:danger] = "Unable to generate lottery tickets"
    end

    redirect_to setup_organization_lottery_path(@organization, @lottery)
  end

  private

  def set_lottery
    @lottery = policy_scope(@organization.lotteries).friendly.find(params[:id])
  end

  def set_organization
    @organization = policy_scope(Organization).friendly.find(params[:organization_id])
  end
end
