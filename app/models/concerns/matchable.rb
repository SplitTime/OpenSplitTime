module Matchable
  # @return [ActiveRecord::Relation<Person>]
  def possible_matching_people
    result = people_with_same_name
      .or(people_changed_last_name)
      .or(people_changed_first_name)
      .or(people_same_full_name)

    result = result.where.not(id: id) if self.is_a?(Person)

    if email.present?
      result = result.email_matches_or_nil(email)
    elsif phone.present?
      result = result.phone_matches_or_nil(phone)
    end

    result
  end

  # @return [Person, nil]
  def definitive_matching_person_by_email
    return unless email.present?

    definitive_matches = potential_matches.first_name_matches(first_name).email_matches(email)
    definitive_matches.one? ? definitive_matches.first : nil
  end

  # @return [Person, nil]
  def definitive_matching_person_by_phone
    return unless phone.present?

    definitive_matches = potential_matches.first_name_matches(first_name).phone_matches(phone)
    definitive_matches.one? ? definitive_matches.first : nil
  end

  # @return [Person, nil]
  def definitive_matching_person_by_birthdate
    return unless birthdate.present?

    definitive_matches = potential_matches.first_name_matches(first_name).where(birthdate: birthdate)
    definitive_matches.one? ? definitive_matches.first : nil
  end

  # @return [Person, nil]
  def exact_matching_person # Suitable for automated matcher
    name_gender_age_match = potential_matches.first_name_matches_exact(first_name).age_matches(current_age)
    name_gender_age_match.one? ? name_gender_age_match.first : nil # Return nil if more than one match
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

  private

  def potential_matches
    result = Person.last_name_matches_exact(last_name).gender_matches(gender)
    result = result.where.not(id: id) if self.is_a?(Person)
    result
  end
end
