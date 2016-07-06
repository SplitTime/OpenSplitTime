class VisitorsController < ApplicationController

  def index
    @skip_footer = true
  end

  def index_old
    @skip_footer = true
  end

  def hardrock
    redirect_to root_path
  end

end
