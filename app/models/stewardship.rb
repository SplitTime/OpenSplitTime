class Stewardship < ActiveRecord::Base
  belongs_to :user
  belongs_to :race
  enum level: [:volunteer, :manager, :owner]

  validates_presence_of :user_id, :race_id
end
