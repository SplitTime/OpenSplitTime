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

  def all_finishes_sorted
    Rails.cache.fetch("/course/#{id}-#{updated_at}/all_finishes_sorted", expires_in: 1.hour) do
      effort_array = []
      events.each do |event|
        event.efforts.each do |effort|
          effort_array << effort if effort.finished?
        end
      end
      effort_array.sort_by { |x| x.finish_split_time.time_from_start }
    end
  end

end
