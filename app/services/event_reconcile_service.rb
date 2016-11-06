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
    auto_matched_count = assign_participants_to_efforts(matched_hash)
    participants_created_count = create_participants_from_efforts(unmatched_array)
    create_effort_reconcile_report(event, auto_matched_count, participants_created_count)
  end

  def self.assign_participants_to_efforts(id_hash)
    efforts = Effort.find(id_hash.keys).index_by(&:id)
    participants = Participant.find(id_hash.values).index_by(&:id)
    id_hash.map { |eid, pid| participants[pid].pull_data_from_effort(efforts[eid]) }.count
  end

  def self.create_participants_from_efforts(effort_ids)
    efforts = Effort.find(effort_ids)
    efforts.map { |effort| Participant.new.pull_data_from_effort(effort) }.count
  end

  # Converts params from reconcile screen to hash of {effort_id => participant_id}
  def self.associate_participants(ids)
    id_hash = Hash[*ids.to_a.flatten.map(&:to_i)]
    assign_participants_to_efforts(id_hash)
  end

  def self.create_effort_reconcile_report(event, auto_matched_count, participants_created_count)
    effort_reconcile_report = ""
    unreconciled_efforts_count = event.unreconciled_efforts.count

    if auto_matched_count > 0
      effort_reconcile_report += "We found #{auto_matched_count} participants that matched our database. "
    else
      effort_reconcile_report += "No participants matched our database exactly. "
    end

    if participants_created_count > 0
      effort_reconcile_report += "We created #{participants_created_count} participants from efforts that had no close matches. "
    end

    if unreconciled_efforts_count > 0
      effort_reconcile_report += "We found #{unreconciled_efforts_count} participants that may or may not match our database. Please reconcile them now. "
    else
      effort_reconcile_report += "All efforts for #{event.name} have been reconciled. "
    end
    effort_reconcile_report
  end

end