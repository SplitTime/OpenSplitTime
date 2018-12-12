# frozen_string_literal: true

class SplitAttributesValidator < ActiveModel::Validator
  def validate(split)
    @split = split
    validate_vert
    validate_distance
    validate_location
    validate_order if split.intermediate?
    validate_group_split_locations
  end

  private

  attr_reader :split

  def validate_vert
    if split.start?
      split.errors.add(:vert_gain_from_start, 'for the start split must be 0') unless split.vert_gain_from_start.nil? || split.vert_gain_from_start.zero?
      split.errors.add(:vert_loss_from_start, 'for the start split must be 0') unless split.vert_loss_from_start.nil? || split.vert_loss_from_start.zero?
    else
      split.errors.add(:vert_gain_from_start, 'may not be negative') if split.vert_gain_from_start&.negative?
      split.errors.add(:vert_loss_from_start, 'may not be negative') if split.vert_loss_from_start&.negative?
    end
  end

  def validate_distance
    if split.start?
      split.errors.add(:distance_from_start, 'for the start split must be 0') unless split.distance_from_start&.zero?
    else
      split.errors.add(:distance_from_start, 'must be positive for intermediate and finish splits') unless split.distance_from_start&.positive?
    end
  end

  def validate_location
    split.errors.add(:elevation, 'must be between -1000 and 10,000 meters') unless split.elevation.nil? || split.elevation.between?(-1000, 10_000)
    split.errors.add(:latitude, 'must be between -90 and 90') unless split.latitude.nil? || split.latitude.between?(-90, 90)
    split.errors.add(:longitude, 'must be between -180 and 180') unless split.longitude.nil? || split.longitude.between?(-180, 180)
  end

  def validate_order
    finish_split_distance = split.course&.finish_split&.distance_from_start
    if split.distance_from_start && finish_split_distance && (split.distance_from_start >= finish_split_distance)
      split.errors.add(:distance_from_start, 'must be less than the finish split distance_from_start')
    end
  end

  def validate_group_split_locations
    event_groups = EventGroup.joins(:events).includes(events: :splits).where(events: {course_id: split.course_id})
    event_conflict_candidates = event_groups.flat_map(&:events).reject { |event| event.course_id == split.course_id }

    event_conflict_candidates.each do |event|
      incompatible_locations = event.splits.select do |other_split|
        (other_split.parameterized_base_name == split.parameterized_base_name) && other_split.different_location?(split)
      end
      if incompatible_locations.present?
        split.errors.add(:base_name, "#{split.base_name} is incompatible with similarly named splits within #{event.name}. " +
            "Splits with duplicate names must have the same locations. ")
      end
    end
  end
end
