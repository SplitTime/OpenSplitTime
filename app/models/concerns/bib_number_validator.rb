class BibNumberValidator < ActiveModel::Validator
  def validate(effort)
    return unless effort.bib_number
    conflicting_effort = Effort.where(event: effort.events_in_group, bib_number: effort.bib_number)
                             .where.not(id: effort.id).first
    if conflicting_effort
      effort.errors.add(:bib_number, "#{effort.bib_number} already exists for #{conflicting_effort.full_name}")
    end
  end
end
