class Stewardship < ApplicationRecord
  belongs_to :user
  belongs_to :organization
  enum level: [:volunteer, :manager, :owner]

  delegate :full_name, :email, to: :user

  validates_presence_of :user_id, :organization_id

  def to_s
    "#{user.slug} for #{organization.slug}"
  end
end
