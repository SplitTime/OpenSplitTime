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

  def split_id_array
    id_array = []
    @splits = splits.sort_by { |x| [x.distance_from_start, x.sub_order] }
    @splits.each do |split|
      id_array << split.id
    end
    id_array
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
    hash = efforts.index_by &:id
    splits = efforts.first.event.splits.ordered
    splits.each do |split|
      split_times = split.split_times
      hash.each_key do |key|
        split_time = split_times.where(effort_id: key).first
        hash[key] = split_time ? split_time.time_from_start : nil
      end
      hash = Hash[hash.sort_by{ |k, v| [v ? 0 : 1, v] }]
    end
    hash.keys
  end

end
