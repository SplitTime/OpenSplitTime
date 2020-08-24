# frozen_string_literal: true

module Api
  module V1
    class SplitSerializer < ::Api::V1::BaseSerializer
      set_type :splits

      attributes :id, :course_id, :distance_from_start, :vert_gain_from_start, :vert_loss_from_start,
                 :kind, :base_name, :name_extensions, :sub_split_kinds, :description, :latitude, :longitude, :elevation

      link :self, :api_v1_url

      belongs_to :course

      def sub_split_kinds
        object.name_extensions
      end
    end
  end
end
