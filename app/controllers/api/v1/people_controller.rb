 class Api::V1::PeopleController < ApiController
  before_action :set_resource, except: [:index, :create]
end
