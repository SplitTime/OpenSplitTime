class Interest < ActiveRecord::Base
  validates_presence_of :user_id, :participant_id
  belongs_to :user
  belongs_to :participant
end
