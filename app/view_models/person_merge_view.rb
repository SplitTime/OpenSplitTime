class PersonMergeView
  attr_reader :person, :proposed_match, :possible_matches
  attr_accessor :effort_counts

  delegate :full_name, :first_name, :last_name, :id, to: :person

  def initialize(person, proposed_match_id)
    @person = person
    @proposed_match = if proposed_match_id.present?
                        Person.find(proposed_match_id)
                      else
                        @person.most_likely_duplicate
                      end
    @possible_matches = @person.possible_matching_people - [@proposed_match]
    set_effort_counts
  end

  private

  def set_effort_counts
    people = possible_matches + [proposed_match] + [person]
    @effort_counts = Effort.group(:person_id).where(person: people).size
  end
end
