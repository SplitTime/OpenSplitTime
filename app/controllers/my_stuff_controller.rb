class MyStuffController < ApplicationController
  before_action :authenticate_user!
  before_action :set_presenter

  def index
  end

  def events
    render partial: "events", locals: { presenter: @presenter }
  end

  def event_series
    render partial: "event_series", locals: { presenter: @presenter }
  end

  def interests
    render partial: "interests", locals: { presenter: @presenter }
  end

  def live_updates
    render partial: "live_updates", locals: { presenter: @presenter }
  end

  def organizations
    render partial: "organizations", locals: { presenter: @presenter }
  end

  def results
    render partial: "results", locals: { presenter: @presenter }
  end

  def service_requirements
    render partial: "service_requirements", locals: { presenter: @presenter }
  end

  private

  def set_presenter
    @presenter = MyStuffPresenter.new(current_user)
  end
end
