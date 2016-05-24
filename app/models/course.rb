class Course < ActiveRecord::Base
  include Auditable
  include SplitMethods
  strip_attributes collapse_spaces: true
  has_many :splits, dependent: :destroy
  has_many :events
  accepts_nested_attributes_for :splits, :reject_if => lambda { |s| s[:distance_from_start].blank? && s[:distance_as_entered].blank? }

  validates_presence_of :name
  validates_uniqueness_of :name, case_sensitive: false

  def earliest_event_date
    events.earliest.start_time
  end

  def latest_event_date
    events.most_recent.start_time
  end

  def update_initial_splits
    splits.start.first.update(base_name: "#{name} Start",
                                         description: "Starting point for the #{name} course.")
    splits.finish.first.update(base_name: "#{name} Finish",
                                          description: "Finish point for the #{name} course.")
  end

  def effort_gender_group(gender)
    case gender
      when 'male'
        Effort.includes(:event).male.where(events: {course_id: id})
      when 'female'
        Effort.includes(:event).female.where(events: {course_id: id})
      else
        Effort.includes(:event).where(events: {course_id: id})
    end
  end

  def relevant_efforts(target_time, max_events = 5, min_efforts = 20)
    relevant_events = events.recent(max_events).includes(:efforts => {:split_times => :split})
    return Effort.none if relevant_events.count < 1
    event_efforts = Effort.where(event_id: relevant_events.pluck(:id).uniq)
    5.step(25, 5) do |i|
      scope_result = event_efforts.within_time_range(target_time * (1-(i/100.0)), target_time * (1+(i/100.0)))
      return scope_result if scope_result.count >= min_efforts
    end
    event_efforts.within_time_range(target_time * 0.7, target_time * 1.3)
  end

end
