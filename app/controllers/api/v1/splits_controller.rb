class Api::V1::SplitsController < ApiController
  before_action :set_resource, except: [:index, :create]
end
