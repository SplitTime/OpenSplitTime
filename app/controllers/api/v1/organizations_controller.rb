# frozen_string_literal: true

module Api
  module V1
    class OrganizationsController < ::Api::V1::BaseController
      before_action :set_resource, except: [:index, :create]
    end
  end
end
