# frozen_string_literal: true

module Matchable
  # @return [ActiveRecord::Relation<Person>]
  def possible_matching_people
    result = people_with_same_name
               .or(people_changed_last_name)
               .or(people_changed_first_name)
               .or(people_same_full_name)

    result = result.where.not(id: id) if self.is_a?(Person)
    result = result.email_matches_or_nil(email) if email.present?
    result = result.phone_matches_or_nil(phone) if phone.present?

    result
  end

  # @return [Person, nil]
  def definitive_matching_person
    return unless birthdate.present? || email.present? || phone.present?

    potential_matches = Person.last_name_matches_exact(last_name)
                          .first_name_matches_exact(first_name)
                          .gender_matches(gender)
    potential_matches = potential_matches.where.not(id: id) if self.is_a?(Person)

    definitive_matches = potential_matches.where.not(birthdate: nil).where(birthdate: birthdate)
                           .or(potential_matches.where.not(email: nil).email_matches(email))
                           .or(potential_matches.where.not(phone: nil).phone_matches(phone))
                           .distinct
    definitive_matches.one? ? definitive_matches.first : nil
  end

  # @return [Person, nil]
  def exact_matching_person # Suitable for automated matcher
    potential_matches = Person.last_name_matches_exact(last_name)
                          .first_name_matches_exact(first_name)
                          .gender_matches(gender)
    potential_matches = potential_matches.where.not(id: id) if self.is_a?(Person)

    name_gender_age_match = potential_matches.age_matches(current_age)
    exact_match = if name_gender_age_match.present?
                    name_gender_age_match
                  else
                    potential_matches.state_matches(state_code)
                  end
    exact_match.one? ? exact_match.first : nil # Convert single match to object; return nil if more than one match
  end

  # @return [Person, nil]
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
