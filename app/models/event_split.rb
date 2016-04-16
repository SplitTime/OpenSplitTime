class EventSplit < ActiveRecord::Base
  belongs_to :event
  belongs_to :split

  validates_presence_of :event_id, :split_id

end
