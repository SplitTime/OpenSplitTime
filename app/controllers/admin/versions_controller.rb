module Admin
  class VersionsController < ApplicationController
    before_action :authenticate_user!
    after_action :verify_authorized

    def index
      authorize Version, policy_class: Admin::VersionPolicy
      @versions = Version.paginate(page: params[:page], per_page: 25).order(created_at: :desc)
    end

    def show
      authorize Version, policy_class: Admin::VersionPolicy
      @version = Version.find_by(id: params[:id])
    end
  end
end
