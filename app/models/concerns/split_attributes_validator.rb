class SplitAttributesValidator < ActiveModel::Validator
  def validate(split)
    @split = split
    validate_vert
    validate_distance
    validate_location
    validate_order if split.intermediate?
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
    finish_split = split.course&.finish_split
    finish_split_distance = finish_split&.distance_from_start
    if split.distance_from_start && finish_split_distance && (split.distance_from_start >= finish_split_distance)
      split.errors.add(:distance_from_start, 'must be less than the finish split distance_from_start')
    end
  end
end
