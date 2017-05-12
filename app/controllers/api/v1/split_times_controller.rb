class Api::V1::SplitTimesController < ApiController
  before_action :set_resource, except: [:index, :create]
end
