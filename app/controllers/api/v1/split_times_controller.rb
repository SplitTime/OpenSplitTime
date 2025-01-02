module Api
  module V1
    class SplitTimesController < ::Api::V1::BaseController
      before_action :set_resource, except: [:index, :create]
    end
  end
end
