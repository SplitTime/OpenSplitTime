# frozen_string_literal: true

module Matchable
  def possible_matching_people
    people_with_same_name
        .or(people_changed_last_name)
        .or(people_changed_first_name)
        .or(people_same_full_name)
        .where.not(id: id)
  end

  def exact_matching_person # Suitable for automated matcher
    potential_matches = Person.last_name_matches_exact(last_name)
        .first_name_matches_exact(first_name)
        .gender_matches(gender)
        .where.not(id: id)
    name_gender_age_match = potential_matches.age_matches(current_age)
    exact_match = if name_gender_age_match.present?
                    name_gender_age_match
                  else
                    potential_matches.state_matches(state_code)
                  end
    exact_match.one? ? exact_match.first : nil # Convert single match to object; return nil if more than one match
  end

  def suggest_close_match
    self.suggested_match = exact_matching_person || possible_matching_people.first
  end

  def people_same_full_name # For situations where middle names are sometimes included with first_name and sometimes with last_name
    Person.full_name_matches(full_name)
  end

  def people_changed_first_name # To pick up discrepancies in first names #TODO use levensthein alagorithm
    Person.last_name_matches_exact(last_name).gender_matches(gender).age_matches(current_age)
  end

  def people_changed_last_name # To find women who may have changed their last names
    return Person.none if male?

    Person.female.first_name_matches_exact(first_name).state_matches(state_code).age_matches(current_age)
  end

  def people_with_nickname # Need to find a good nickname gem
    # Person.last_name_matches(last_name).first_name_nickname(first_name).first
  end

  def people_with_same_name
    Person.last_name_matches(last_name).first_name_matches(first_name)
  end
end
