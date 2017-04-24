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

  def letsencrypt
    render text: 'f7SCiRQj_3fSn1LT5Fl8Xq1-8r3HJBOZvhW7yJBoumo.20VIu5GrWXpBuayTk5wFfCYYm_nsv5EsaqKG3MmFLM0'
  end
end
