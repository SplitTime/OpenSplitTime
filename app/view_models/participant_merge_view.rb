class ParticipantMergeView

  attr_reader :participant, :proposed_match, :possible_matches
  attr_accessor :effort_counts
  delegate :full_name, :first_name, :last_name, :id, to: :participant

  def initialize(participant, proposed_match_id)
    @participant = participant
    @proposed_match = proposed_match_id.present? ?
        Participant.find(proposed_match_id) :
        @participant.most_likely_duplicate
    @possible_matches = @participant.possible_matching_participants - [@proposed_match]
    set_effort_counts
  end

  def proposed_match_name
    "#{proposed_match.last_name}, #{proposed_match.first_name}"
  end
  
  private

  def set_effort_counts
    participants = possible_matches + [proposed_match] + [participant]
    @effort_counts = Effort.group(:participant_id).where(participant: participants).size
  end
end