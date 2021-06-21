class ImportJobsController < ApplicationController
  before_action :authenticate_user!
  after_action :verify_authorized, except: :index

  def index
    @user = current_user
  end
end

