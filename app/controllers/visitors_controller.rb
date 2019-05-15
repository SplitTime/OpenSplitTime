# frozen_string_literal: true

class VisitorsController < ApplicationController
  def index
    @skip_footer = true
    @presenter = VisitorIndexPresenter.new(current_user)
  end
end
