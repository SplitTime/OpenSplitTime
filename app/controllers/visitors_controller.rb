class VisitorsController < ApplicationController

  def index
    @skip_footer = true
    @presenter = VisitorIndexPresenter.new(current_user)
  end

  def documentation
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
end
