# frozen_string_literal: true

class Docs::VisitorsController < ApplicationController
  def index
    @presenter = Docs::IndexPresenter.new(params, current_user)
    render :docs
  end

  def getting_started
    @presenter = Docs::GettingStartedPresenter.new(params, current_user)
    render :docs
  end

  def management
    @presenter = Docs::ManagementPresenter.new(params, current_user)
    render :docs
  end

  def ost_remote
    @presenter = Docs::OstRemotePresenter.new(params, current_user)
    render :docs
  end

  def api
    @presenter = Docs::ApiPresenter.new(params, current_user)
    render :docs
  end
end
