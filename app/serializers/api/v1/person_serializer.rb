# frozen_string_literal: true

module Api
  module V1
    class PersonSerializer < ::Api::V1::BaseSerializer
      attributes :id, :first_name, :last_name, :full_name, :gender, :current_age, :city, :state_code, :country_code
      %i[phone email birthdate].each { |att| attribute att, if: :show_personal_info? }

      link(:self) { api_v1_person_path(object) }

      has_many :efforts
    end
  end
end
