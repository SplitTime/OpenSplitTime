# frozen_string_literal: true

module Api
  module V1
    class OrganizationSerializer < ::Api::V1::BaseSerializer
      attributes :id, :name, :description, :concealed, :editable
      link :self, :url
    end
  end
end
