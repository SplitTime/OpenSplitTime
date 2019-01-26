# frozen_string_literal: true

class AidStation < ApplicationRecord
  belongs_to :event
  belongs_to :split

  validates_uniqueness_of :split_id, scope: :event_id,
                          message: 'only one of any given split permitted within an event'
  validates_presence_of :event_id, :split_id
  validates_with AidStationAttributesValidator

  attr_accessor :efforts_dropped_at_station, :efforts_in_aid, :efforts_recorded_out,
                :efforts_passed_without_record, :efforts_expected
  delegate :course, :distance_from_start, to: :split
  delegate :event_group, to: :event
  delegate :organization, to: :event_group

  scope :ordered, -> { includes(:split).order('splits.distance_from_start') }

  def to_s
    "#{event.slug} at #{split.slug}"
  end

  def course_name
    course.name
  end

  def event_name
    event.name
  end

  def organization_name
    organization.name
  end

  def split_name
    split.base_name
  end
end
