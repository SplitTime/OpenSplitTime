json.array!(@participants) do |participant|
  json.extract! participant, :id, :participant_id, :first_name, :last_name, :gender, :birthdate, :home_city, :home_state, :home_country
  json.url participant_url(participant, format: :json)
end
