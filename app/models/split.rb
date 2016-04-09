class Split < ActiveRecord::Base
  enum kind: [:start, :finish, :waypoint]
  belongs_to :course
  belongs_to :location
  has_many :split_times, dependent: :destroy
  has_many :event_splits, dependent: :destroy
  has_many :events, through: :event_splits

  accepts_nested_attributes_for :location, allow_destroy: true

  validates_presence_of :course_id, :name, :distance_from_start, :sub_order, :kind
  validates :kind, inclusion: {in: Split.kinds.keys}
  validates_uniqueness_of :name, scope: :course_id, case_sensitive: false
  validates_uniqueness_of :distance_from_start, scope: [:course_id, :sub_order]
  validates_uniqueness_of :kind, scope: :course_id, if: 'is_start?',
                          message: "only one start split permitted on a course"
  validates_uniqueness_of :kind, scope: :course_id, if: 'is_finish?',
                          message: "only one finish split permitted on a course"
  validates_numericality_of :distance_from_start, equal_to: 0, if: 'is_start?',
                            message: "for the start split must be 0"
  validates_numericality_of :vert_gain_from_start, equal_to: 0, if: 'is_start?', allow_nil: true,
                            message: "for the start split must be 0"
  validates_numericality_of :vert_loss_from_start, equal_to: 0, if: 'is_start?', allow_nil: true,
                            message: "for the start split must be 0"
  validates_numericality_of :distance_from_start, greater_than: 0, :unless => 'is_start?',
                            message: "must be positive for waypoint and finish splits"
  validates_numericality_of :vert_gain_from_start, greater_than_or_equal_to: 0, allow_nil: true,
                            message: "may not be negative"
  validates_numericality_of :vert_loss_from_start, greater_than_or_equal_to: 0, allow_nil: true,
                            message: "may not be negative"

  def is_start?
    kind == "start"
  end

  def is_finish?
    kind == "finish"
  end

  def self.to_csv(options = {})
    CSV.generate(options) do |csv|
      csv << column_names
      all.each do |split|
        csv << split.attributes.values_at(*column_names)
      end
    end
  end

  def self.ordered
    order(:distance_from_start, :sub_order)
  end

  def waypoint_group
    course.splits.where(distance_from_start: distance_from_start).order(:sub_order)
  end

end
