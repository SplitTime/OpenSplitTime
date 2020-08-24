# frozen_string_literal: true

module Api
  module V1
    class CoursesController < ::Api::V1::BaseController
      before_action :set_resource, except: [:index, :create]
      before_action :authenticate_user!, except: :show
      after_action :verify_authorized, except: :show

      def show
        serialize_and_render(@resource)
      end
    end
  end
end
