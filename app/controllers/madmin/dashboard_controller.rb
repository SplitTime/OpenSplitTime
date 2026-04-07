module Madmin
  class DashboardController < Madmin::ApplicationController
    def timeout
      Rails.logger.info "Sleeping for 35 seconds to produce an intentional timeout"
      sleep 35
      Rails.logger.info "Done sleeping"

      redirect_to madmin_root_path
    end
  end
end
