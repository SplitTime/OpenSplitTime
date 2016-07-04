class VisitorsController < ApplicationController

  def hardrock
    @skip_footer = true
  end

  def index
    @skip_footer = true
  end

  def photo_credits
    render partial: 'photo_credits'
  end

end
