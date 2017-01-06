class EventReconcileService

  def self.auto_reconcile_efforts(event)
    EffortAutoReconciler.new(event).report
  end

  def self.assign_participants_to_efforts(id_hash)
    efforts = Effort.find(id_hash.keys).index_by(&:id)
    participants = Participant.find(id_hash.values).index_by(&:id)
    id_hash.map { |eid, pid| participants[pid].associate_effort(efforts[eid]) }.size
  end

  def self.create_participants_from_efforts(effort_ids)
    efforts = Effort.find(Array.wrap(effort_ids))
    efforts.map { |effort| Participant.new.associate_effort(effort) }.size
  end

  def self.associate_participants(params)
    id_hash = Hash[*params.to_a.flatten.map(&:to_i)]
    assign_participants_to_efforts(id_hash)
  end
end