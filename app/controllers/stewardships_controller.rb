# frozen_string_literal: true

class StewardshipsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_organization
  before_action :authorize_organization
  before_action :set_stewardship, only: [:update, :destroy]
  after_action :verify_authorized

  def index
    @presenter = ::OrganizationPresenter.new(@organization, view_context)
  end

  def create
    user = User.find_by(email: params[:email])

    if user
      @stewardship = @organization.stewardships.new(user: user)

      unless @stewardship.save
        flash[:warning] = "User #{user.full_name} could not be added as a steward.\n#{@stewardship.errors.full_messages.join("\n")}"
      end
    else
      flash[:warning] = "No user with email #{params[:email]} was located."
    end

    redirect_to organization_stewardships_path(@organization)
  end

  def update
    if @stewardship.update(permitted_params)
      flash[:success] = "Stewardship updated."
    else
      flash[:danger] = "Unable to update stewardship."
    end

    redirect_to organization_stewardships_path(@organization)
  end

  def destroy
    @stewardship.destroy

    redirect_to organization_stewardships_path(@organization)
  end

  private

  def authorize_organization
    authorize @organization, policy_class: ::StewardshipPolicy
  end

  def set_organization
    @organization = policy_scope(::Organization).friendly.find(params[:organization_id])
  end

  def set_stewardship
    @stewardship = @organization.stewardships.find(params[:id])
  end
end
