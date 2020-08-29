# frozen_string_literal: true

module Api
  module V1
    class OrganizationSerializer < ::Api::V1::BaseSerializer
      set_type :organizations

      attributes :id, :name, :description, :concealed
      link :self, :api_v1_url
    end
  end
end
