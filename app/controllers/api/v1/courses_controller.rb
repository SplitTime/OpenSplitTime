class Api::V1::CoursesController < ApiController
  before_action :set_resource, except: [:index, :create]
end
