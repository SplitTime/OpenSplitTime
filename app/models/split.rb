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

  validates_presence_of :base_name, :distance_from_start, :sub_split_bitmap, :kind
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

  scope :ordered, -> { order(:distance_from_start) }

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

  def time_hash(sub_split_bitkey)
    Hash[SplitTime.where(split_id: id, sub_split_bitkey: sub_split_bitkey).pluck(:effort_id, :time_from_start)]
  end

  def average_time(sub_split_bitkey, relevant_efforts)
    split_times.where(sub_split_bitkey: sub_split_bitkey, effort: relevant_efforts).pluck(:time_from_start).mean
  end

  def name(bitkey = nil)
    if bitkey
      name_extensions.count > 1 ? [base_name, SubSplit.kind(bitkey)].compact.join(' ') : base_name
    else
      extensions = name_extensions.count > 1 ? name_extensions.join(' / ') : nil
      [base_name, extensions].compact.join(' ')
    end
  end

  def name_extensions
    sub_split_bitkeys.map { |bitkey| SubSplit.kind(bitkey) }
  end

  def sub_split_bitkey_hashes
    sub_split_bitkeys.map { |bitkey| {id => bitkey} }
  end

  alias_method :bitkey_hashes, :sub_split_bitkey_hashes

  def sub_split_bitkeys
    SubSplit.reveal_valid_bitkeys(sub_split_bitmap)
  end

  alias_method :bitkeys, :sub_split_bitkeys

  def bitkey_hash_in
    bitkeys.include?(SubSplit::IN_BITKEY) ? {id => SubSplit::IN_BITKEY} : nil
  end

  def bitkey_hash_out
    bitkeys.include?(SubSplit::OUT_BITKEY) ? {id => SubSplit::OUT_BITKEY} : nil
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
