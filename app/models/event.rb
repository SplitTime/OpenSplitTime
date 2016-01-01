class Event < ActiveRecord::Base
  belongs_to :course
  belongs_to :event_series
end
