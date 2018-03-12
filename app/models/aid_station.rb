# frozen_string_literal: true

class AidStation < ApplicationRecord
  belongs_to :event
  belongs_to :split
  enum status: [:pre_open, :open, :closed, :released]

  validates_uniqueness_of :split_id, scope: :event_id,
                          message: 'only one of any given split permitted within an event'
  validates_presence_of :event_id, :split_id
  validates_with AidStationAttributesValidator

  attr_accessor :efforts_dropped_at_station, :efforts_in_aid, :efforts_recorded_out,
                :efforts_passed_without_record, :efforts_expected
  delegate :course, :distance_from_start, to: :split

  scope :ordered, -> { includes(:split).order('splits.distance_from_start') }

  def to_s
    "#{event.slug} at #{split.slug}"
  end

  def course_name
    course.name
  end

  def event_group
    event.event_group
  end

  def event_name
    event.name
  end

  def organization
    event_group.organization
  end

  def organization_name
    organization.name
  end

  def split_name
    split.base_name
  end
end
