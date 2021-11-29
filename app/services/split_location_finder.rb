# frozen_string_literal: true

class SplitLocationFinder

  def self.splits(params)
    new(params).splits
  end

  def initialize(params)
    @params = params
  end

  def splits
    Split.with_course_name.where(course_id: course_ids_within_bounds)
        .where.not(latitude: nil).where.not(longitude: nil)
  end

  private

  attr_reader :params

  def course_ids_within_bounds
    splits_within_bounds.pluck(:course_id).uniq
  end

  def splits_within_bounds
    location_bounds[:west] > location_bounds[:east] ?
        Split.location_bounded_across_dateline(location_bounds) :
        Split.location_bounded_by(location_bounds)
  end

  def location_bounds
    params.slice(:west, :east, :south, :north).transform_values(&:to_f)
  end
end
