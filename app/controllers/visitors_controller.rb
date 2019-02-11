class VisitorsController < ApplicationController

  def index
    @skip_footer = true
    @presenter = VisitorIndexPresenter.new
  end
end
