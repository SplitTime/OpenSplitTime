class Api::V1::OrganizationsController < ApiController
  before_action :set_resource, except: [:index, :create]
end
