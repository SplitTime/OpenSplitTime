class EffortSerializer < BaseSerializer
  attributes :id, :event_id, :participant_id, :bib_number, :first_name, :last_name, :full_name, :gender,
             :birthdate, :age, :city, :state_code, :country_code
end