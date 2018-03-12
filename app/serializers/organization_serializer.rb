# frozen_string_literal: true

class OrganizationSerializer < BaseSerializer
  attributes :id, :name, :description, :concealed, :editable
  link(:self) { api_v1_organization_path(object) }
end
