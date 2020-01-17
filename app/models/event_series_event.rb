class EventSeriesEvent < ApplicationRecord
  belongs_to :event_series, optional: false
  belongs_to :event, optional: false

  validates_presence_of :event_series, :event
end
