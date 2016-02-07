class Split < ActiveRecord::Base

  enum kind: [:start, :finish, :waypoint]
  belongs_to :course
  belongs_to :location

  validates_presence_of :course_id, :location_id, :name, :distance_from_start, :sub_order, :kind
  validates_uniqueness_of :name, scope: :course_id
  validates_uniqueness_of :distance_from_start, scope: [:course_id, :sub_order]
  validates_uniqueness_of :kind, scope: :course_id, :if => 'split_is_start?', :message => "only one start split permitted on a course"
  validates_uniqueness_of :kind, scope: :course_id, :if => 'split_is_finish?', :message => "only one finish split permitted on a course"
  validates_numericality_of :distance_from_start, equal_to: 0, :if => 'split_is_start?', :message => "the start split must have 0 distance from start"
  validates_numericality_of :vert_gain_from_start, equal_to: 0, :if => 'split_is_start?', allow_nil: true, :message => "the start split vert_gain must be 0"
  validates_numericality_of :vert_loss_from_start, equal_to: 0, :if => 'split_is_start?', allow_nil: true, :message => "the start split vert_loss must be 0"

  def split_is_start?
    kind == "start"
  end

  def split_is_finish?
    kind == "finish"
  end

end
