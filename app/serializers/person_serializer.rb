class PersonSerializer < BaseSerializer
  attributes :id, :first_name, :last_name, :full_name, :gender, :current_age, :city, :state_code, :country_code
  link(:self) { api_v1_participant_path(object) }

  has_many :efforts
end
