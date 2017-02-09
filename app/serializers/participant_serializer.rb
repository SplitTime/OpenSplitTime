class ParticipantSerializer < ActiveModel::Serializer
  attributes :id, :first_name, :last_name, :gender, :birthdate,
             :city, :state_code, :country_code, :email, :phone
end