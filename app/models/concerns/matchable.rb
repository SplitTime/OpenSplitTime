module Matchable

  include SetOperations

  def possible_matching_participants
    Participant.union_scope(self.participants_with_same_name,
                self.participants_changed_last_name,
                self.participants_changed_first_name,
                self.participants_same_full_name)
        .where.not(id: self.id)
  end

  def exact_matching_participant # Suitable for automated matcher
    possible_matching_participants = Participant.last_name_matches_exact(last_name)
                                         .first_name_matches_exact(first_name)
                                         .gender_matches(gender)
                                         .where.not(id: self.id)
    name_gender_age_match = possible_matching_participants.age_matches(age_today)
    exact_match = name_gender_age_match.present? ?
        name_gender_age_match :
        possible_matching_participants.state_matches(state_code)
    exact_match.count == 1 ? exact_match.first : nil # Convert single match to object; return nil if more than one match
  end

  def suggest_close_match
    self.suggested_match = possible_matching_participants.first
  end

  def participants_same_full_name # For situations where middle names are sometimes included with first_name and sometimes with last_name
    Participant.full_name_matches(full_name)
  end

  def participants_changed_first_name # To pick up discrepancies in first names #TODO use levensthein alagorithm
    Participant.last_name_matches_exact(last_name).gender_matches(gender).age_matches(age_today)
  end

  def participants_changed_last_name # To find women who may have changed their last names
    Participant.female.first_name_matches_exact(first_name).state_matches(state_code).age_matches(age_today)
  end

  def participants_with_nickname # Need to find a good nickname gem
    # Participant.last_name_matches(last_name).first_name_nickname(first_name).first
  end

  def participants_with_same_name
    Participant.last_name_matches(last_name).first_name_matches(first_name)
  end

end
