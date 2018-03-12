# frozen_string_literal: true

class Stewardship < ApplicationRecord
  belongs_to :user
  belongs_to :organization
  enum level: [:volunteer, :manager, :owner]

  delegate :full_name, :email, to: :user

  validates_presence_of :user_id, :organization_id
  validates_uniqueness_of :user_id, scope: :organization_id, message: "is already a steward of this organization."

  def to_s
    "#{user.slug} for #{organization.slug}"
  end
end
