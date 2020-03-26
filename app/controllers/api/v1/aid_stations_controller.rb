module Api
  module V1
    class AidStationsController < ::Api::V1::BaseController
      before_action :set_resource, except: [:index, :create]
    end
  end
end
