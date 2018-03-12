# frozen_string_literal: true

class PersonMergeView

  attr_reader :person, :proposed_match, :possible_matches
  attr_accessor :effort_counts
  delegate :full_name, :first_name, :last_name, :id, to: :person

  def initialize(person, proposed_match_id)
    @person = person
    @proposed_match = proposed_match_id.present? ?
        Person.find(proposed_match_id) :
        @person.most_likely_duplicate
    @possible_matches = @person.possible_matching_people - [@proposed_match]
    set_effort_counts
  end

  def proposed_match_name
    "#{proposed_match.last_name}, #{proposed_match.first_name}"
  end
  
  private

  def set_effort_counts
    people = possible_matches + [proposed_match] + [person]
    @effort_counts = Effort.group(:person_id).where(person: people).size
  end
end
