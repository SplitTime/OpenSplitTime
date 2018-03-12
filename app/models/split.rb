# frozen_string_literal: true

class Split < ApplicationRecord
  DISTANCE_THRESHOLD = 100 # Distance (in meters) below which split locations are deemed equivalent

  include Auditable
  include Locatable
  include GuaranteedFindable
  include UnitConversions
  extend FriendlyId
  strip_attributes collapse_spaces: true
  friendly_id :course_split_name, use: [:slugged, :history]
  enum kind: [:start, :finish, :intermediate]
  belongs_to :course
  has_many :split_times
  has_many :live_times
  has_many :aid_stations, dependent: :destroy
  has_many :events, through: :aid_stations

  validates_presence_of :base_name, :distance_from_start, :sub_split_bitmap, :kind
  validates :kind, inclusion: {in: Split.kinds.keys}
  validates_uniqueness_of :kind, scope: :course_id, if: :start?,
                          message: 'only one start split permitted on a course'
  validates_uniqueness_of :kind, scope: :course_id, if: :finish?,
                          message: 'only one finish split permitted on a course'
  validates_uniqueness_of :distance_from_start, scope: :course_id,
                          message: 'only one split of a given distance permitted on a course. Use sub_splits if needed.'
  validates_with SplitAttributesValidator
  attribute :kind, default: :intermediate

  scope :ordered, -> { order(:distance_from_start) }
  scope :with_course_name, -> { select('splits.*, courses.name as course_name').joins(:course) }
  scope :location_bounded_by, -> (params) { where(latitude: params[:south]..params[:north],
                                                  longitude: params[:west]..params[:east]) }
  scope :location_bounded_across_dateline, -> (params) { where(latitude: params[:south]..params[:north])
                                                             .where.not(longitude: params[:east]..params[:west]) }

  def self.null_record
    @null_record ||= Split.new(base_name: '[not found]', description: '', sub_split_bitmap: 0)
  end

  def to_s
    slug
  end

  def distance_in_preferred_units
    Split.meters_to_preferred_distance(distance_from_start).round(2) if distance_from_start
  end
  alias_method :distance, :distance_in_preferred_units

  def distance_in_preferred_units=(number_string)
    self.distance_from_start = Split.entered_distance_to_meters(number_string) if number_string.present?
  end
  alias_method :distance=, :distance_in_preferred_units=

  def vert_gain_in_preferred_units
    Split.meters_to_preferred_elevation(vert_gain_from_start).round(0) if vert_gain_from_start
  end
  alias_method :vert_gain, :vert_gain_in_preferred_units

  def vert_gain_in_preferred_units=(number_string)
    self.vert_gain_from_start = Split.entered_elevation_to_meters(number_string) if number_string.present?
  end
  alias_method :vert_gain=, :vert_gain_in_preferred_units=

  def vert_loss_in_preferred_units
    Split.meters_to_preferred_elevation(vert_loss_from_start).round(0) if vert_loss_from_start
  end
  alias_method :vert_loss, :vert_loss_in_preferred_units

  def vert_loss_in_preferred_units=(number_string)
    self.vert_loss_from_start = Split.entered_elevation_to_meters(number_string) if number_string.present?
  end
  alias_method :vert_loss=, :vert_loss_in_preferred_units=

  def elevation_in_preferred_units
    Split.meters_to_preferred_elevation(elevation) if elevation
  end

  def elevation_in_preferred_units=(entered_elevation)
    if entered_elevation.present?
      self.elevation = Split.entered_elevation_to_meters(entered_elevation)
    else
      self.elevation = nil
    end
  end

  def course_split_name
    "#{course_name} #{base_name}"
  end

  def should_generate_new_friendly_id?
    slug.blank? || base_name_changed? || course&.name_changed?
  end

  def parameterized_base_name
    base_name.parameterize
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

  alias_method :sub_split_kinds, :name_extensions

  def name_extensions=(extensions)
    name_extension_array = extensions.respond_to?(:map) ? extensions : extensions.to_s.split
    bitkeys = name_extension_array.map { |name_extension| SubSplit.bitkey(name_extension) }.compact
    if bitkeys.present?
      self.sub_split_bitmap = bitkeys.inject(:|)
    else
      self.sub_split_bitmap = SubSplit::IN_BITKEY
    end
  end

  alias_method :sub_split_kinds=, :name_extensions=

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

  def course_name
    @course_name ||= attributes['course_name'] || course&.name
  end

  def earliest_event_date
    events.visible.earliest&.start_time
  end

  def most_recent_event_date
    events.visible.most_recent&.start_time
  end

  def live_entry_attributes
    {title: base_name,
     entries: sub_split_bitkeys.map { |bitkey| {split_id: id, sub_split_kind: SubSplit.kind(bitkey).downcase, label: name(bitkey)} }}
  end
end
