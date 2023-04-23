class ResultsTemplatesController < ApplicationController
  before_action :set_results_template

  def show
    respond_to do |format|
      format.turbo_stream
    end
  end

  private

  def set_results_template
    @results_template = ResultsTemplate.find(params[:id])
  end
end
