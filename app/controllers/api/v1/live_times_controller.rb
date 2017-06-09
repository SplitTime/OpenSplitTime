class Api::V1::LiveTimesController < ApiController
  before_action :set_resource, except: [:index, :create]
end
