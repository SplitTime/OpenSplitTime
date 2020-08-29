# frozen_string_literal: true

module Api
  module V1
    class UsersController < ::Api::V1::BaseController
      before_action :set_resource, except: [:index, :create, :current]

      def current
        authorize User
        serialize_and_render(current_user)
      end
    end
  end
end
