class EventReconcileService

  def self.auto_reconcile_efforts(event)
    matched_hash = {}
    unmatched_array = []
    event.unreconciled_efforts.each do |effort|
      participant_exact_match = effort.exact_matching_participant
      if participant_exact_match # Exact match so assign to participant
        matched_hash[effort.id] = participant_exact_match.id
      elsif effort.suggest_close_match.blank? # No close matches so make new participants
        unmatched_array << effort.id
      end
    end
    return assign_participants_to_efforts(matched_hash),
        create_participants_from_efforts(unmatched_array)
  end

  def self.assign_participants_to_efforts(id_hash)
    efforts = Effort.find(id_hash.keys).index_by(&:id)
    participants = Participant.find(id_hash.values).index_by(&:id)
    counter = 0
    id_hash.each do |effort_id, participant_id|
      counter += 1 if participants[participant_id].pull_data_from_effort(efforts[effort_id])
    end
    counter
  end

  def self.create_participants_from_efforts(effort_ids)
    counter = 0
    efforts = Effort.where(id: effort_ids)
    efforts.each do |effort|
      @participant = Participant.new
      counter += 1 if @participant.pull_data_from_effort(effort)
    end
    counter
  end

  # Converts params from reconcile screen to hash of {effort_id => participant_id}
  def self.associate_participants(ids)
    id_hash = Hash[*ids.to_a.flatten.map(&:to_i)]
    assign_participants_to_efforts(id_hash)
  end

end