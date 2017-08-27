class EventReconcileService

  def self.assign_participants_to_efforts(id_hash)
    id_hash = id_hash.transform_keys(&:to_i).transform_values(&:to_i)
    efforts = Effort.find(id_hash.keys).index_by(&:id)
    participants = Participant.find(id_hash.values).index_by(&:id)
    result = id_hash.map { |eid, pid| participants[pid].associate_effort(efforts[eid]) }
    result.compact.size
  end

  def self.create_participants_from_efforts(effort_ids)
    efforts = Effort.find(Array.wrap(effort_ids))
    efforts.map { |effort| Participant.new.associate_effort(effort) }.size
  end
end
