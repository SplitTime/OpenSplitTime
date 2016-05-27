class Split < ActiveRecord::Base
  include Auditable
  include UnitConversions
  strip_attributes collapse_spaces: true
  enum kind: [:start, :finish, :intermediate]
  belongs_to :course
  belongs_to :location
  has_many :split_times, dependent: :destroy
  has_many :event_splits, dependent: :destroy
  has_many :events, through: :event_splits

  accepts_nested_attributes_for :location, allow_destroy: true

  validates_presence_of :base_name, :distance_from_start, :sub_split_mask, :kind
  validates :kind, inclusion: {in: Split.kinds.keys}
  validates_uniqueness_of :base_name, scope: :course_id, case_sensitive: false,
                          message: "must be unique for a course"
  validates_uniqueness_of :kind, scope: :course_id, if: 'is_start?',
                          message: "only one start split permitted on a course"
  validates_uniqueness_of :kind, scope: :course_id, if: 'is_finish?',
                          message: "only one finish split permitted on a course"
  validates_uniqueness_of :distance_from_start, scope: :course_id,
                          message: "only one split of a given distance permitted on a course. Use sub_splits if needed."
  validates_numericality_of :distance_from_start, equal_to: 0, if: 'is_start?',
                            message: "for the start split must be 0"
  validates_numericality_of :vert_gain_from_start, equal_to: 0, if: 'is_start?', allow_nil: true,
                            message: "for the start split must be 0"
  validates_numericality_of :vert_loss_from_start, equal_to: 0, if: 'is_start?', allow_nil: true,
                            message: "for the start split must be 0"
  validates_numericality_of :distance_from_start, greater_than: 0, :unless => 'is_start?',
                            message: "must be positive for intermediate and finish splits"
  validates_numericality_of :vert_gain_from_start, greater_than_or_equal_to: 0, allow_nil: true,
                            message: "may not be negative"
  validates_numericality_of :vert_loss_from_start, greater_than_or_equal_to: 0, allow_nil: true,
                            message: "may not be negative"

  scope :ordered, -> { where(sub_order: 0).order(:distance_from_start) } # Remove sub_order constraint when migration is complete

  def is_start?
    self.start?
  end

  def is_finish?
    self.finish?
  end

  def distance_as_entered
    Split.distance_in_preferred_units(distance_from_start, User.current).round(2) if distance_from_start
  end

  def distance_as_entered=(entered_distance)
    self.distance_from_start = Split.distance_in_meters(entered_distance.to_f, User.current) if entered_distance.present?
  end

  def vert_gain_as_entered
    Split.elevation_in_preferred_units(vert_gain_from_start, User.current).round(0) if vert_gain_from_start
  end

  def vert_gain_as_entered=(entered_vert_gain)
    self.vert_gain_from_start = Split.elevation_in_meters(entered_vert_gain.to_f, User.current) if entered_vert_gain.present?
  end

  def vert_loss_as_entered
    Split.elevation_in_preferred_units(vert_loss_from_start, User.current).round(0) if vert_loss_from_start
  end

  def vert_loss_as_entered=(entered_vert_loss)
    self.vert_loss_from_start = Split.elevation_in_meters(entered_vert_loss.to_f, User.current) if entered_vert_loss.present?
  end

  def self.average_times(target_finish_time) # Returns a hash with split ids => average times from start
    efforts = first.course.relevant_efforts(target_finish_time)
    return_hash = {}
    all.each do |split|
      return_hash[split.id] = split.average_time(efforts)
    end
    return_hash
  end

  def time_hash
    Hash[SplitTime.where(split_id: id).pluck(:effort_id, :time_from_start)]
  end

  def average_time(relevant_efforts)
    split_times.where(effort_id: relevant_efforts.pluck(:id)).pluck(:time_from_start).mean
  end

  def sub_split_key_hashes
    sub_split_keys.map { |key| {id => key} }
  end

  def name
    extensions = name_extensions.count > 1 ? name_extensions.join(' / ') : nil
    [base_name, extensions].compact.join(' ')
  end

  def name_extensions
    sub_splits.pluck(:kind)
  end

  def sub_split_keys
    SubSplit.reveal_keys(sub_split_mask)
  end

  def sub_splits
    SubSplit.where('sub_splits.bitkey & ? > 0', sub_split_mask).order(:bitkey)
  end

  def name=(entered_name)
    if entered_name.present?
      self.base_name = entered_name.split.reject { |x| (x.downcase == 'in') | (x.downcase == 'out') }.join(' ')
      self.name_extension = entered_name.gsub(base_name, '').strip
    end
  end

  def course_index # Returns an integer representing the split's relative position on the course
    course.ordered_split_ids.index(id)
  end

  def earliest_event_date
    events.earliest.start_time
  end

  def latest_event_date
    events.most_recent.start_time
  end

  def random_location_name
    "#{name} Location #{(rand * 1000).to_i} (please change me)"
  end

end
