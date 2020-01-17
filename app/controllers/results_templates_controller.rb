class ResultsTemplatesController < ApplicationController
  before_action :set_results_template

  def categories
    render partial: 'categories_card', locals: {template: @results_template}
  end

  private

  def set_results_template
    @results_template = ResultsTemplate.find(params[:id])
  end
end
