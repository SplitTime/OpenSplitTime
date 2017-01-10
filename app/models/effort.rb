class Effort < ActiveRecord::Base
  enum data_status: [:bad, :questionable, :good] # nil = unknown, 0 = bad, 1 = questionable, 2 = good
  enum gender: [:male, :female]
  strip_attributes collapse_spaces: true

  VALID_STATUSES = [nil, data_statuses[:good]]

  include Auditable
  include Concealable
  include DataStatusMethods
  include GuaranteedFindable
  include PersonalInfo
  include Searchable
  include Matchable
  belongs_to :event
  belongs_to :participant
  has_many :split_times, dependent: :destroy
  accepts_nested_attributes_for :split_times, :reject_if => lambda { |s| s[:time_from_start].blank? && s[:elapsed_time].blank? }

  attr_accessor :over_under_due, :next_expected_split_time, :suggested_match, :segment_time
  attr_writer :overall_place, :gender_place, :last_reported_split_time, :event_start_time

  validates_presence_of :event_id, :first_name, :last_name, :gender
  validates_uniqueness_of :participant_id, scope: :event_id, allow_blank: true
  validates_uniqueness_of :bib_number, scope: :event_id, allow_nil: true
  validate :dropped_attributes_consistent

  before_save :reset_age_from_birthdate

  scope :ordered_by_date, -> { includes(:event).order('events.start_time DESC') }
  scope :on_course, -> (course) { includes(:event).where(events: {course_id: course.id}) }
  scope :unreconciled, -> { where(participant_id: nil) }
  scope :finished, -> { select('efforts.*, split_times.lap')
                            .joins(:event).joins(:split_times => :split)
                            .where(splits: {kind: 1}).where('split_times.lap >= events.laps_required')
                            .order('split_times.lap desc').uniq }
  scope :started, -> { joins(split_times: :split).where(splits: {kind: 0}).uniq }

  delegate :race, to: :event

  def self.null_record
    @null_record ||= Effort.new(first_name: '', last_name: '')
  end

  def self.attributes_for_import
    id = ['id']
    foreign_keys = Effort.column_names.find_all { |x| x.include?('_id') }
    stamps = Effort.column_names.find_all { |x| x.include?('_at') | x.include?('_by') }
    (column_names - (id + foreign_keys + stamps)).map(&:to_sym)
  end

  def self.search(param)
    case
    when param.blank?
      all
    when param.numeric?
      where(bib_number: param.to_i)
    else
      flexible_search(param)
    end
  end

  def self.sorted_with_finish_status(limited: false)
    return [] if existing_scope_sql.blank?
    query = <<-SQL
    WITH
        existing_scope AS (#{existing_scope_sql}),
        efforts_scoped AS (SELECT efforts.*
                                       FROM efforts
                                       INNER JOIN existing_scope ON existing_scope.id = efforts.id)
     SELECT #{limited ? 'id' : '*'}, 
            rank() over 
              (ORDER BY dropped, 
                        final_lap desc, 
                        distance_from_start desc, 
                        time_from_start, 
                        gender desc, 
                        age desc) 
            AS overall_rank, 
            rank() over 
              (PARTITION BY gender 
               ORDER BY dropped, 
                        final_lap desc, 
                        distance_from_start desc, 
                        time_from_start, 
                        gender desc, 
                        age desc) 
            AS gender_rank,
            CASE 
              when final_lap >= laps_required then true 
              else false 
            END 
            AS finished
      FROM 
            (SELECT DISTINCT ON(efforts_scoped.id) 
                efforts_scoped.*,
                events.laps_required,
                CASE 
                  when efforts_scoped.dropped_split_id is null then false 
                  else true 
                END 
                AS dropped, 
                splits.id as final_split_id, 
                splits.base_name as final_split_name, 
                splits.distance_from_start, 
                split_times.lap as final_lap, 
                split_times.time_from_start, 
                split_times.sub_split_bitkey 
            FROM efforts_scoped
                INNER JOIN split_times ON split_times.effort_id = efforts_scoped.id 
                INNER JOIN splits ON splits.id = split_times.split_id
                INNER JOIN events ON events.id = efforts_scoped.event_id
            ORDER BY  efforts_scoped.id, 
                      split_times.lap desc, 
                      splits.distance_from_start desc, 
                      split_times.sub_split_bitkey desc) 
            AS subquery
      ORDER BY overall_rank
    SQL
    self.find_by_sql(query)
  end

  def self.existing_scope_sql
    # have to do this to get the binds interpolated. remove any ordering and just grab the ID
    self.connection.unprepared_statement {self.reorder(nil).select("id").to_sql}
  end
  private_class_method(:existing_scope_sql)

  def dropped_attributes_consistent
    errors.add(:dropped_split_id, 'a dropped_split_id exists with no dropped_lap') if dropped_split_id && !dropped_lap
    errors.add(:dropped_lap, 'a dropped_lap exists with no dropped_split_id') if !dropped_split_id && dropped_lap
  end

  def reset_age_from_birthdate
    assign_attributes(age: TimeDifference.between(birthdate, event_start_time).in_years.to_i) if birthdate.present?
  end

  def start_time
    @start_time ||= event_start_time + start_offset
  end

  def start_time=(datetime)
    return unless datetime.present?
    new_datetime = datetime.is_a?(Hash) ? Time.zone.local(*datetime.values) : datetime
    self.start_offset = TimeDifference.from(new_datetime, event_start_time).in_seconds
  end

  def event_start_time
    @event_start_time ||= event.start_time
  end

  def event_name
    @event_name ||= event.name
  end

  def laps_required
    @laps_required ||= event.laps_required
  end

  def last_reported_split_time
    @last_reported_split_time ||= ordered_split_times.last
  end

  def valid_split_times
    @valid_split_times ||= split_times.valid_status.ordered
  end

  def finish_split_times
    @finish_split_times ||= split_times.finish.ordered
  end

  def start_split_times
    @start_split_times ||= split_times.start.ordered
  end

  def finish_split_time
    finish_split_times.last if finished?
  end

  def start_split_time
    start_split_times.first
  end

  def laps_finished
    finish_split_times.size
  end

  def laps_started
    start_split_times.size
  end

  def finished?
    laps_finished >= laps_required
  end

  def started?
    start_split_times.present?
  end

  def dropped?
    dropped_split_id.present?
  end

  def in_progress?
    started? && !dropped? && !finished?
  end

  def finish_status
    case
    when !started?
      'Not yet started'
    when dropped?
      'DNF'
    when finished?
      finish_split_time.formatted_time_hhmmss
    else
      'In progress'
    end
  end

  def time_in_aid(split)
    time_array = ordered_split_times(split).map(&:time_from_start)
    time_array.size > 1 ? time_array.last - time_array.first : nil
  end

  def total_time_in_aid
    @total_time_in_aid ||= ordered_split_times.group_by(&:split_id)
                               .inject(0) { |total, (_, group)| total + (group.last.time_from_start - group.first.time_from_start) }
  end

  def ordered_splits
    @ordered_splits ||= event.ordered_splits
  end

  def ordered_split_times(split = nil)
    split ? split_times.where(split: split).order(:sub_split_bitkey) : split_times.ordered
  end

  def combined_places
    @combined_places ||= event.combined_places(self)
  end

  def overall_place
    @overall_place ||= event.overall_place(self)
  end

  def gender_place
    @gender_place ||= event.gender_place(self)
  end

  def approximate_age_today
    @approximate_age_today ||=
        age && (TimeDifference.from(event_start_time.to_date, Time.now.utc.to_date).in_years + age).to_i
  end

  def unreconciled?
    participant_id.nil?
  end

  def set_dropped_attributes
    update(dropped_split_id: dropped_attributes[:split_id], dropped_lap: dropped_attributes[:lap])
    dropped_attributes
  end

  private

  def dropped_attributes
    @dropped_attributes ||= {split_id: dropped_split_time.split_id, lap: dropped_split_time.lap}
  end

  def dropped_split_time
    @dropped_split_time ||= finished? ? SplitTime.null_record : ordered_split_times.last
  end
end