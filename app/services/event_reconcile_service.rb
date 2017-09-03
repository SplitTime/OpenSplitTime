class EventReconcileService

  def self.assign_people_to_efforts(id_hash)
    id_hash = id_hash.transform_keys(&:to_i).transform_values(&:to_i)
    efforts = Effort.find(id_hash.keys).index_by(&:id)
    people = Person.find(id_hash.values).index_by(&:id)
    result = id_hash.map { |eid, pid| people[pid].associate_effort(efforts[eid]) }
    result.compact.size
  end

  def self.create_people_from_efforts(effort_ids)
    efforts = Effort.find(Array.wrap(effort_ids))
    efforts.map { |effort| Person.new.associate_effort(effort) }.size
  end
end
