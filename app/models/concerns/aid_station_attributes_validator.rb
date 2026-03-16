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
    return unless event && split && event.course_id != split.course_id

    errors.add(:event_id, "event's course is not the same as split's course")
  end

  def validate_group_split_locations
    event_group = EventGroup.includes(events: :splits).find_by(id: event&.event_group_id)
    return unless event_group

    incompatible_locations = EventGroupSplitAnalyzer.new(event_group).incompatible_locations
    return unless incompatible_locations.include?(split.parameterized_base_name)

    errors.add(:split,
               "#{split.base_name} is incompatible with similarly named splits within " \
               "event group #{event_group}. Splits with duplicate names must have the same locations.")
  end
end
