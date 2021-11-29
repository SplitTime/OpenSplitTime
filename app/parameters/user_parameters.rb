# frozen_string_literal: true

class UserParameters < BaseParameters

  def self.permitted_query
    permitted + [:confirmed_at, :role, :avatar_first_name, :avatar_last_name]
  end

  def self.permitted
    [:id, :first_name, :last_name, :email, :phone, :http, :https, :password, :pref_distance_unit, :pref_elevation_unit]
  end
end
