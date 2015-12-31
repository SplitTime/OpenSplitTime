json.participants @participants do |participant|
  json.id            participant.id
  json.first_name    participant.first_name
  json.last_name     participant.last_name
  json.gender        participant.gender
  json.birthdate     participant.birthdate
  json.home_city     participant.home_city
  json.home_state    participant.home_state
  json.home_country  participant.home_country
end
