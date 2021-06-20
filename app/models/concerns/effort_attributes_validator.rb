# frozen_string_literal: true

class EffortAttributesValidator < ActiveModel::Validator
  def validate(effort)
    validate_split_times(effort)
    validate_bib_number(effort)
    validate_person(effort)
  end

  private

  def validate_split_times(effort)
    event_course_id = effort.event&.course_id
    if event_course_id && effort.split_times.joins(:split).pluck(:course_id).any? { |course_id| course_id != event_course_id }
      effort.errors.add(:event, "course doesn't reconcile with split_times => split => course")
    end
  end

  def validate_bib_number(effort)
    return unless effort.bib_number && effort.will_save_change_to_bib_number?

    conflicting_effort = Effort.where(event: effort.events_within_group, bib_number: effort.bib_number)
                             .where.not(id: effort.id).first
    if conflicting_effort
      effort.errors.add(:bib_number, "#{effort.bib_number} already exists for #{conflicting_effort.full_name}")
    end
  end

  def validate_person(effort)
    return unless effort.person_id && effort.will_save_change_to_person_id?

    conflicting_person = Effort.where(event: effort.events_within_group, person_id: effort.person)
                             .where.not(id: effort.id).first&.person
    if conflicting_person
      effort.errors.add(:person, "#{effort.person} has already been entered in #{effort.event_group}")
    end
  end
end
