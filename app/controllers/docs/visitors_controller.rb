# frozen_string_literal: true

class Docs::VisitorsController < ApplicationController
  def contents
    render_using_presenter(Docs::ContentsPresenter)
  end

  def getting_started
    render_using_presenter(Docs::GettingStartedPresenter)
  end

  def management
    render_using_presenter(Docs::ManagementPresenter)
  end

  def ost_remote
    render_using_presenter(Docs::OstRemotePresenter)
  end

  def api
    render_using_presenter(Docs::ApiPresenter)
  end

  private

  def render_using_presenter(presenter)
    @presenter = presenter.new(params, current_user)
    raise ActionController::RoutingError, 'Not Found' unless @presenter.valid_params?

    render :docs
  end
end
