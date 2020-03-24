# frozen_string_literal: true

class UserSerializer < BaseSerializer
  attributes :id, :first_name, :last_name, :email, :pref_distance_unit, :pref_elevation_unit
end
