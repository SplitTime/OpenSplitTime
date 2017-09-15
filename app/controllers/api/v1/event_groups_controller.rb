class Api::V1::EventGroupsController < ApiController
  before_action :set_resource, except: [:index, :create]
end
