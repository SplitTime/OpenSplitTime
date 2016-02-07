class Interest < ActiveRecord::Base
  enum kind: [:casual, :pending_active, :active]   # default is 0; 0 = casual, 1 = pending_active, 2 = active
  belongs_to :user
  belongs_to :participant

  validates_presence_of :user_id, :participant_id, :kind
end
