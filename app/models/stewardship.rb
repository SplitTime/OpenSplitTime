class Stewardship < ApplicationRecord
  has_paper_trail

  belongs_to :user
  belongs_to :organization
  enum :level, [:volunteer, :lottery_manager]

  delegate :full_name, :email, to: :user

  validates_presence_of :user, :organization
  validates_uniqueness_of :user_id, scope: :organization_id, message: "is already a steward of this organization."

  def to_s
    "#{user.slug} for #{organization.slug}"
  end
end
