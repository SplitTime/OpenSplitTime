class Event < ActiveRecord::Base
  belongs_to :course
  belongs_to :race
  has_many :efforts, dependent: :destroy
  has_many :event_splits, dependent: :destroy
  has_many :splits, through: :event_splits

  validates_presence_of :course_id, :name, :first_start_time
  validates_uniqueness_of :name, case_sensitive: false

  def all_splits_on_course?
    splits.each do |split|
      return false if split.course_id != course_id
    end
    true
  end

  def split_kind_count
    kind_array = splits.map(&:kind)
    kind_array.inject(Hash.new(0)) { |total, e| total[e] += 1; total }
  end

  def split_ids
    splits.ordered.map &:id
  end

  def unreconciled_efforts
    efforts.where(participant_id: nil)
  end

  def unreconciled_efforts?
    efforts.where(participant_id: nil).count > 0
  end

  def race_sorted_efforts
    effort_array = []
    race_sorted_ids.each do |id|
      effort = Effort.find(id)
      effort_array << effort
    end
    effort_array
  end

  def race_sorted_ids
    return [] if efforts.none?
    sort_hash = efforts.index_by &:id
    splits = efforts.first.event.splits.ordered
    splits.each do |split|
      time_hash = split.split_times.index_by &:effort_id
      sort_hash.each_key do |key|
        time = time_hash[key] ? time_hash[key].time_from_start : nil
        sort_hash[key] = time
      end
      sort_hash = Hash[sort_hash.sort_by{ |k, v| [v ? 0 : 1, v] }]
    end
    sort_hash.keys
  end

end
