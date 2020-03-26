# frozen_string_literal: true

module Api
  module V1
    class OrganizationSerializer < ::Api::V1::BaseSerializer
      attributes :id, :name, :description, :concealed, :editable
      link(:self) { api_v1_organization_path(object) }
    end
  end
end
