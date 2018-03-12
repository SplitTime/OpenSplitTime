# frozen_string_literal: true

class AidStationAttributesValidator < ActiveModel::Validator
  def validate(aid_station)
    @aid_station = aid_station
    validate_course_consistency
    validate_group_split_locations
  end

  private

  attr_reader :aid_station
  delegate :event, :split, :errors, to: :aid_station

  def validate_course_consistency
    if event && split && event.course_id != split.course_id
      errors.add(:event_id, "event's course is not the same as split's course")
    end
  end

  def validate_group_split_locations
    event_group = EventGroup.where(id: event&.event_group_id).includes(events: :splits).first
    return unless event_group
    incompatible_locations = EventGroupSplitAnalyzer.new(event_group).incompatible_locations
    if incompatible_locations.include?(split.parameterized_base_name)
      errors.add(:split, "#{split.base_name} is incompatible with similarly named splits within event group #{event_group}. " +
          "Splits with duplicate names must have the same locations. ")
    end
  end
end
