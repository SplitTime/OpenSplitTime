# frozen_string_literal: true

module Api
  module V1
    class CourseSerializer < ::Api::V1::BaseSerializer
      attributes :id, :name, :description, :track_points
      attribute(:editable) do |course, params|
        current_user = params[:current_user]
        current_user.nil? ? false : Pundit.policy!(current_user, course).update?
      end
      attribute :locations do |course|
        course.ordered_splits.select(&:has_location?).map do |split|
          {id: split.id, base_name: split.base_name, latitude: split.latitude, longitude: split.longitude}
        end
      end

      link :self, :api_url

      has_many :splits
      belongs_to :organization
    end
  end
end
