class Effort < ActiveRecord::Base
  validates_presence_of :event_id, :participant_id, :start_time
  validates_uniqueness_of :participant_id, scope: :event_id
  belongs_to :event
  belongs_to :participant
end
