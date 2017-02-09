class OrganizationSerializer < ActiveModel::Serializer
  attributes :id, :name, :description, :concealed
end