class Api::V1::ParticipantsController < ApiController
  before_action :set_resource, except: [:index, :create]
end
