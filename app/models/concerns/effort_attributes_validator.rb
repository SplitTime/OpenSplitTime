# frozen_string_literal: true

class EffortAttributesValidator < ActiveModel::Validator
  def validate(effort)
    validate_split_times(effort)
    validate_bib_number(effort)
    validate_names_and_birthdates(effort)
    validate_person(effort)
  end

  private

  def validate_split_times(effort)
    record_event_course = effort.event&.course
    if record_event_course && effort.split_times.eager_load(split: :course).any? { |st| st.split.course != record_event_course }
      effort.errors.add(:event, "course doesn't reconcile with split_times => split => course")
    end
  end

  def validate_bib_number(effort)
    return unless effort.bib_number

    conflicting_effort = ::Effort.where(event: effort.events_within_group, bib_number: effort.bib_number)
                                 .where.not(id: effort.id).first

    if conflicting_effort.present?
      message = "#{effort.bib_number} already exists for #{conflicting_effort.full_name}"
      effort.errors.add(:bib_number, message)
    end
  end

  def validate_names_and_birthdates(effort)
    return unless effort.birthdate?

    conflicting_effort = ::Effort.where(event: effort.events_within_group)
                                 .where(first_name: effort.first_name, last_name: effort.last_name, birthdate: effort.birthdate)
                                 .where.not(id: effort.id).first

    if conflicting_effort.present?
      message = "#{effort.full_name} with birthdate #{effort.birthdate} already exists for bib number #{conflicting_effort.bib_number} (id #{conflicting_effort.id})"
      effort.errors.add(:base, message)
    end
  end

  def validate_person(effort)
    return unless effort.person_id

    conflicting_person = Effort.where(event: effort.events_within_group, person_id: effort.person)
                               .where.not(id: effort.id).first&.person
    if conflicting_person
      effort.errors.add(:person, "#{effort.person} has already been entered in #{effort.event_group}")
    end
  end
end
