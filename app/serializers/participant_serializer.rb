class ParticipantSerializer < BaseSerializer
  attributes :id, :first_name, :last_name, :full_name, :gender, :birthdate,
             :city, :state_code, :country_code, :email, :phone
end