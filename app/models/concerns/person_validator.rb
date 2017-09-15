class PersonValidator < ActiveModel::Validator
  def validate(effort)
    return unless effort.person_id
    conflicting_person = Effort.where(event: effort.events_within_group, person_id: effort.person)
                             .where.not(id: effort.id).first&.person
    if conflicting_person
      effort.errors.add(:person, "#{effort.person} has already been entered in #{effort.event_group}")
    end
  end
end
