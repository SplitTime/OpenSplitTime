class Course < ActiveRecord::Base
  has_many :splits, dependent: :destroy
  has_many :events
  accepts_nested_attributes_for :splits, allow_destroy: true

  validates_presence_of :name
  validates_uniqueness_of :name, case_sensitive: false

  def earliest_event_date
    events.order(:first_start_time).first.first_start_time
  end

  def latest_event_date
    events.order(:first_start_time).last.first_start_time
  end

  def sorted_efforts
    effort_array = []
    sorted_effort_ids.each do |id|
      effort = Effort.find(id)
      effort_array << effort
    end
    effort_array
  end

  def sorted_effort_ids
    Rails.cache.fetch("/course/#{id}-#{updated_at}/all_finishes_sorted", expires_in: 30.days) do
      sort_hash = {}
      events.each do |event|
        event.efforts.each do |effort|
          sort_hash[effort.id] = effort.finish_split_time.time_from_start if effort.finished?
        end
      end
      effort_array = Hash[sort_hash.sort_by { |k, v| v }].keys
      effort_array
    end
  end

end
