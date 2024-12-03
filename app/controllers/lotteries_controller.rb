# frozen_string_literal: true

class LotteriesController < ApplicationController
  before_action :authenticate_user!, except: [:index, :show]
  before_action :set_organization
  before_action :authorize_organization, except: [:index, :show]
  before_action :set_lottery, except: [:index, :new, :create]
  after_action :verify_authorized, except: [:index, :show]

  # GET /organizations/:organization_id/lotteries
  def index
    @presenter = ::OrganizationPresenter.new(@organization, view_context)
  end

  # GET /organizations/:organization_id/lotteries/:id
  def show
    @presenter = ::LotteryPresenter.new(@lottery, view_context)

    respond_to do |format|
      format.html
      format.turbo_stream
    end
  end

  # GET /organizations/:organization_id/lotteries/new
  def new
    @lottery = @organization.lotteries.new
  end

  # GET /organizations/:organization_id/lotteries/:id/edit
  def edit
  end

  # POST /organizations/:organization_id/lotteries
  def create
    @lottery = @organization.lotteries.new(permitted_params)

    if @lottery.save
      redirect_to setup_organization_lottery_path(@organization, @lottery)
    else
      render "new", status: :unprocessable_entity
    end
  end

  # PUT /organizations/:organization_id/lotteries/:id
  # PATCH /organizations/:organization_id/lotteries/:id
  def update
    if @lottery.update(permitted_params)
      redirect_to setup_organization_lottery_path(@organization, @lottery), notice: "Lottery updated"
    else
      render "edit", status: :unprocessable_entity
    end
  end

  # DELETE /organizations/:organization_id/lotteries/:id
  def destroy
    if @lottery.destroy
      flash[:success] = "Lottery deleted."
      redirect_to organization_lotteries_path
    else
      flash[:danger] = @lottery.errors.full_messages.join("\n")
      redirect_to organization_lottery_path(@organization, @lottery)
    end
  end

  # GET /organizations/:organization_id/lotteries/:id/calculations
  def calculations
    @presenter = Lotteries::CalculationsPresenter.new(@lottery, view_context)
  end

  # POST /organizations/:organization_id/lotteries/:id/sync_calculations
  def sync_calculations
    if @lottery.calculation_class?
      Lotteries::SyncCalculationsJob.perform_later(@lottery)
      redirect_to setup_organization_lottery_path(@organization, @lottery), notice: "Sync in progress"
    else
      redirect_to setup_organization_lottery_path(@organization, @lottery), alert: "Lottery does not have a calculations_class"
    end
  end

  # GET /organizations/:organization_id/lotteries/:id/draw_tickets
  def draw_tickets
    @presenter = LotteryPresenter.new(@lottery, view_context)
  end

  # GET /organizations/:organization_id/lotteries/:id/setup
  def setup
    @presenter = LotteryPresenter.new(@lottery, view_context)
  end

  # GET /organizations/:organization_id/lotteries/:id/withdraw_entrants
  def withdraw_entrants
    @presenter = LotteryPresenter.new(@lottery, view_context)
  end

  # GET /organizations/:organization_id/lotteries/:id/export_entrants
  def export_entrants
    respond_to do |format|
      format.csv do
        export_format = params[:export_format]&.to_sym

        case export_format
        when :ultrasignup
          entrants = @lottery.divisions.flat_map(&:accepted_entrants)
          filename = "#{@lottery.name}-export-for-ultrasignup-#{Time.now.strftime('%Y-%m-%d')}.csv"
          csv_stream = render_to_string(partial: "ultrasignup", formats: :csv, locals: { records: entrants })

          send_data(csv_stream, type: "text/csv", filename: filename)
        when :results
          filename = "#{@lottery.name}-results-#{Time.now.strftime('%Y-%m-%d')}.csv"
          csv_stream = render_to_string(partial: "results", formats: :csv, locals: { lottery: @lottery })

          send_data(csv_stream, type: "text/csv", filename: filename)
        else
          entrants = @lottery.entrants.ordered_for_export.where(prepared_params[:filter])
          builder = ::CsvBuilder.new(::LotteryEntrant, entrants)
          filename = if prepared_params[:filter] == { "id" => "0" }
            "lottery-entrants-template.csv"
          else
            "#{prepared_params[:filter].to_param}-#{builder.model_class_name}-#{Time.now.strftime('%Y-%m-%d')}.csv"
          end

          send_data(builder.full_string, type: "text/csv", filename: filename)
        end
      end
    end
  end

  # POST /organizations/:organization_id/lotteries/:id/draw
  def draw
    division = @lottery.divisions.find(params[:division_id])
    lottery_draw = division.draw_ticket!

    if lottery_draw.present?
      head :created
    else
      head :no_content
    end
  end

  # DELETE /organizations/:organization_id/lotteries/:id/delete_draws
  def delete_draws
    if @lottery.delete_all_draws! && @lottery.entrants.update_all(withdrawn: false)
      flash[:success] = "Deleted all lottery draws"
    else
      flash[:danger] = "Unable to delete all lottery draws"
    end

    redirect_to setup_organization_lottery_path(@organization, @lottery)
  end

  # DELETE /organizations/:organization_id/lotteries/:id/delete_entrants
  def delete_entrants
    begin
      if @lottery.draws.delete_all &&
        @lottery.tickets.delete_all &&
        @lottery.divisions.each { |division| division.entrants.delete_all }
        flash[:success] = "Deleted all lottery entrants, tickets, and draws"
      else
        flash[:danger] = "Unable to delete all lottery entrants, tickets, and draws"
      end
    rescue ::ActiveRecord::ActiveRecordError => e
      flash[:danger] = "Unable to delete entrants, tickets, and draws: #{e}"
    end

    redirect_to setup_organization_lottery_path(@organization, @lottery)
  end

  # DELETE /organizations/:organization_id/lotteries/:id/delete_tickets
  def delete_tickets
    if @lottery.draws.delete_all && @lottery.tickets.delete_all
      flash[:success] = "Deleted all lottery tickets and draws"
    else
      flash[:danger] = "Unable to delete all lottery tickets and draws"
    end

    redirect_to setup_organization_lottery_path(@organization, @lottery)
  end

  # POST /organizations/:organization_id/lotteries/:id/generate_entrants
  def generate_entrants
    if @lottery.divisions.present?
      if @lottery.generate_entrants!
        flash[:success] = "Generated lottery entrants"
      else
        flash[:danger] = "Unable to generate lottery entrants"
      end
    else
      flash[:danger] = "Add at least one division first"
    end

    redirect_to setup_organization_lottery_path(@organization, @lottery)
  end

  # POST /organizations/:organization_id/lotteries/:id/generate_tickets
  def generate_tickets
    if @lottery.entrants.present?
      if @lottery.delete_and_insert_tickets!
        flash[:success] = "Generated lottery tickets"
      else
        flash[:danger] = "Unable to generate lottery tickets"
      end
    else
      flash[:danger] = "You need to add entrants first"
    end

    redirect_to setup_organization_lottery_path(@organization, @lottery)
  end

  private

  def authorize_organization
    authorize @organization, policy_class: ::LotteryPolicy
  end

  def set_lottery
    @lottery = policy_scope(@organization.lotteries).friendly.find(params[:id])
  end

  def set_organization
    @organization = policy_scope(::Organization).friendly.find(params[:organization_id])
  end
end
