class EventReconcileService

  def self.create_people_from_efforts(effort_ids)
    efforts = Effort.find(Array.wrap(effort_ids))
    efforts.map { |effort| Person.new.associate_effort(effort) }.size
  end
end
