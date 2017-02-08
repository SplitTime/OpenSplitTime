class Stewardship < ActiveRecord::Base
  belongs_to :user
  belongs_to :organization
  enum level: [:volunteer, :manager, :owner]

  validates_presence_of :user_id, :organization_id
end
