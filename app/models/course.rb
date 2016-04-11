class Course < ActiveRecord::Base
  has_many :splits, dependent: :destroy
  has_many :events
  accepts_nested_attributes_for :splits, :reject_if => lambda { |s| s[:distance_from_start].blank? }

  validates_presence_of :name
  validates_uniqueness_of :name, case_sensitive: false

  def earliest_event_date
    events.order(:first_start_time).first.first_start_time
  end

  def latest_event_date
    events.order(:first_start_time).last.first_start_time
  end

  def update_initial_splits
    splits.start.first.update_attributes(name: "#{name} Start",
                                         description: "Starting point for the #{name} course.")
    splits.finish.first.update_attributes(name: "#{name} Finish",
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
    relevant_events = most_recent_events(max_events).includes(:efforts => {:split_times => :split})
    return Effort.none if relevant_events.count < 1
    event_efforts = Effort.where(event_id: relevant_events.pluck(:id).uniq)
    5.step(25, 5) do |i|
      scope_result = event_efforts.within_time_range(target_time * (1-(i/100.0)), target_time * (1+(i/100.0)))
      return scope_result if scope_result.count >= min_efforts
    end
    event_efforts.within_time_range(target_time * 0.7, target_time * 1.3)
  end

  def most_recent_events(max_events)
    events.order(first_start_time: :desc).limit(max_events) || Event.none
  end

end
