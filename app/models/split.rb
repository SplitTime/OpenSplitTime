class Split < ActiveRecord::Base

  include Auditable
  include Concealable
  include GuaranteedFindable
  include UnitConversions
  extend FriendlyId
  friendly_id :course_split_name, use: :slugged
  strip_attributes collapse_spaces: true
  enum kind: [:start, :finish, :intermediate]
  belongs_to :course
  has_many :split_times
  has_many :aid_stations, dependent: :destroy
  has_many :events, through: :aid_stations

  validates_presence_of :base_name, :distance_from_start, :sub_split_bitmap, :kind
  validates :kind, inclusion: {in: Split.kinds.keys}
  validates_uniqueness_of :base_name, scope: :course_id, case_sensitive: false,
                          message: 'must be unique for a course'
  validates_uniqueness_of :kind, scope: :course_id, if: 'is_start?',
                          message: 'only one start split permitted on a course'
  validates_uniqueness_of :kind, scope: :course_id, if: 'is_finish?',
                          message: 'only one finish split permitted on a course'
  validates_uniqueness_of :distance_from_start, scope: :course_id,
                          message: 'only one split of a given distance permitted on a course. Use sub_splits if needed.'
  validates_numericality_of :distance_from_start, equal_to: 0, if: 'is_start?',
                            message: 'for the start split must be 0'
  validates_numericality_of :vert_gain_from_start, equal_to: 0, if: 'is_start?', allow_nil: true,
                            message: 'for the start split must be 0'
  validates_numericality_of :vert_loss_from_start, equal_to: 0, if: 'is_start?', allow_nil: true,
                            message: 'for the start split must be 0'
  validates_numericality_of :distance_from_start, greater_than: 0, :unless => 'is_start?',
                            message: 'must be positive for intermediate and finish splits'
  validates_numericality_of :vert_gain_from_start, greater_than_or_equal_to: 0, allow_nil: true,
                            message: 'may not be negative'
  validates_numericality_of :vert_loss_from_start, greater_than_or_equal_to: 0, allow_nil: true,
                            message: 'may not be negative'
  validates_numericality_of :elevation, greater_than_or_equal_to: -1000, less_than_or_equal_to: 10000, allow_nil: true
  validates_numericality_of :latitude, greater_than_or_equal_to: -90, less_than_or_equal_to: 90, allow_nil: true
  validates_numericality_of :longitude, greater_than_or_equal_to: -180, less_than_or_equal_to: 180, allow_nil: true

  scope :ordered, -> { order(:distance_from_start) }
  scope :with_course_name, -> { select('splits.*, courses.name as course_name').joins(:course) }
  scope :location_bounded_by, -> (params) { where(latitude: params[:south]..params[:north],
                                                  longitude: params[:west]..params[:east]) }
  scope :location_bounded_across_dateline, -> (params) { where(latitude: params[:south]..params[:north])
                                                             .where.not(longitude: params[:east]..params[:west]) }

  def self.null_record
    @null_record ||= Split.new(base_name: '[not found]', description: '', sub_split_bitmap: 0)
  end

  def is_start?
    self.start?
  end

  def is_finish?
    self.finish?
  end

  def distance_as_entered
    Split.meters_to_preferred_distance(distance_from_start).round(2) if distance_from_start
  end

  def distance_as_entered=(number_string)
    self.distance_from_start = Split.entered_distance_to_meters(number_string) if number_string.present?
  end

  def vert_gain_as_entered
    Split.meters_to_preferred_elevation(vert_gain_from_start).round(0) if vert_gain_from_start
  end

  def vert_gain_as_entered=(number_string)
    self.vert_gain_from_start = Split.entered_elevation_to_meters(number_string) if number_string.present?
  end

  def vert_loss_as_entered
    Split.meters_to_preferred_elevation(vert_loss_from_start).round(0) if vert_loss_from_start
  end

  def vert_loss_as_entered=(number_string)
    self.vert_loss_from_start = Split.entered_elevation_to_meters(number_string) if number_string.present?
  end

  def elevation_as_entered
    Split.meters_to_preferred_elevation(elevation) if elevation
  end

  def elevation_as_entered=(entered_elevation)
    if entered_elevation.present?
      self.elevation = Split.entered_elevation_to_meters(entered_elevation)
    else
      self.elevation = nil
    end
  end

  def course_split_name
    "#{course_name} #{base_name}"
  end

  def name(bitkey = nil)
    if bitkey
      name_extensions.size > 1 ? [base_name, SubSplit.kind(bitkey)].compact.join(' ') : base_name
    else
      extensions = name_extensions.size > 1 ? name_extensions.join(' / ') : nil
      [base_name, extensions].compact.join(' ')
    end
  end

  def name_extensions
    sub_split_bitkeys.map { |bitkey| SubSplit.kind(bitkey) }
  end

  def name_extensions=(extensions)
    name_extension_array = extensions.respond_to?(:map) ? extensions : extensions.to_s.split
    bitkeys = name_extension_array.map { |name_extension| SubSplit.bitkey(name_extension) }.compact
    if bitkeys.present?
      self.sub_split_bitmap = bitkeys.inject(:|)
    else
      self.sub_split_bitmap = SubSplit::IN_BITKEY
    end
  end

  def sub_splits
    sub_split_bitkeys.map { |bitkey| {id => bitkey} }
  end

  def sub_split_bitkeys
    SubSplit.reveal_valid_bitkeys(sub_split_bitmap)
  end

  alias_method :bitkeys, :sub_split_bitkeys

  def sub_split_in
    {id => in_bitkey} if in_bitkey
  end

  def in_bitkey
    bitkeys.find { |bitkey| bitkey == SubSplit::IN_BITKEY }
  end

  def sub_split_out
    {id => out_bitkey} if out_bitkey
  end

  def out_bitkey
    bitkeys.find { |bitkey| bitkey == SubSplit::OUT_BITKEY }
  end

  def course_index # Returns an integer representing the split's relative position on the course
    course.ordered_split_ids.index(id)
  end

  def course_name
    @course_name ||= attributes['course_name'] || course.try(:name)
  end

  def earliest_event_date
    events.where(concealed: false).earliest.start_time
  end

  def latest_event_date
    events.where(concealed: false).latest.start_time
  end

  def most_recent_event_date
    events.where(concealed: false).most_recent.start_time
  end
end
