# frozen_string_literal: true

module Api
  module V1
    class UserSerializer < ::Api::V1::BaseSerializer
      attributes :id, :first_name, :last_name, :email, :pref_distance_unit, :pref_elevation_unit
    end
  end
end
