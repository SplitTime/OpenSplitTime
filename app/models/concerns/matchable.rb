module Matchable

  def participants_same_full_name # For situations where middle names are sometimes included with first_name and sometimes with last_name
    participants = Participant.gender_matches(gender) # To limit pool of search options
    Participant.full_name_matches(full_name, participants) || Participant.none
  end

  def participants_changed_first_name # To pick up discrepancies in first names #TODO use levensthein alagorithm
    participants = Participant.last_name_matches(last_name).gender_matches(gender).all
    Participant.age_matches(age_today, participants) || Participant.none
  end

  def participants_changed_last_name # To find women who may have changed their last names
    participants = Participant.female.first_name_matches(first_name).state_matches(state_code).all
    Participant.age_matches(age_today, participants) || Participant.none
  end

  def participants_with_nickname # Need to find a good nickname gem
    # Participant.last_name_matches(last_name).first_name_nickname(first_name).first
    Participant.none
  end

  def participants_with_same_name
    Participant.last_name_matches(last_name).first_name_matches(first_name) || Participant.none
  end

  def possible_matching_participants
    ((participants_with_same_name) +
        (participants_with_nickname) +
        (participants_changed_last_name) +
        (participants_changed_first_name) +
        (participants_same_full_name)).uniq
    # return participant_with_nickname if participant_with_nickname
  end

  def exact_matching_participant # Suitable for automated matcher
    participants = Participant.last_name_matches(last_name, rigor: 'exact')
                       .first_name_matches(first_name, rigor: 'exact').gender_matches(gender)
    name_gender_age_match = Participant.age_matches(age_today, participants, 'soft')
    exact_match = name_gender_age_match.present? ? name_gender_age_match : participants.state_matches(state_code)
    exact_match.count == 1 ? exact_match.first : nil # Convert single match to object; don't pass if more than one match
  end

end
