class Course < ActiveRecord::Base
  PERMITTED_PARAMS = [:id, :name, :description, :next_start_time]

  include Auditable
  include Concealable
  include SplitMethods
  strip_attributes collapse_spaces: true
  has_many :splits, dependent: :destroy
  has_many :events
  accepts_nested_attributes_for :splits, :reject_if => lambda { |s| s[:distance_from_start].blank? && s[:distance_as_entered].blank? }

  scope :used_for_organization, -> (organization) { joins(:events).where(events: {organization_id: organization.id}).uniq }

  validates_presence_of :name
  validates_uniqueness_of :name, case_sensitive: false

  def earliest_event_date
    events.earliest.start_time
  end

  def latest_event_date
    events.latest.start_time
  end

  def most_recent_event_date
    events.most_recent.start_time
  end

  def update_initial_splits
    splits.start.first.update(description: "Starting point for the #{name} course.") if splits.start.present?
    splits.finish.first.update(description: "Finish point for the #{name} course.") if splits.finish.present?
  end

  def visible_events
    events.visible
  end

  def lap_splits_through(lap)
    cycled_lap_splits.first(lap * ordered_splits.size)
  end

  def cycled_lap_splits # For events with unlimited laps, call #cycled_lap_splits.first(n)
    ordered_splits.each_with_iteration { |split, i| LapSplit.new(i, split) }
  end

  def time_points_through(lap)
    cycled_time_points.first(lap * sub_splits.size)
  end

  def cycled_time_points # For events with unlimited laps, call #cycled_time_points.first(n)
    sub_splits.each_with_iteration { |sub_split, i| TimePoint.new(i, sub_split.split_id, sub_split.bitkey) }
  end

  def distance
    @distance ||= ordered_splits.last.distance_from_start if ordered_splits.present?
  end

  def vert_gain
    @vert_gain ||= ordered_splits.last.vert_gain_from_start if ordered_splits.present?
  end

  def vert_loss
    @vert_loss ||= ordered_splits.last.vert_loss_from_start if ordered_splits.present?
  end
end