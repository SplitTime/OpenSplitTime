# frozen_string_literal: true

module Api
  module V1
    class CoursesController < ::Api::V1::BaseController
      before_action :set_resource, except: [:index, :create]
      before_action :authenticate_user!, except: :show
      after_action :verify_authorized, except: :show

      def show
        render json: ::Api::V1::CourseSerializer.new(@resource, {include: params[:include], fields: prepared_params[:fields]}).to_hash
      end
    end
  end
end
