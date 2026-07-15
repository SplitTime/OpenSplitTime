class Organization < ApplicationRecord
  include UrlAccessible
  include Concealable
  include Auditable
  extend FriendlyId

  strip_attributes collapse_spaces: true
  friendly_id :name, use: [:slugged, :history]
  has_paper_trail

  belongs_to :owner, class_name: "User", foreign_key: "created_by"

  has_many :courses, dependent: :destroy
  has_many :course_groups, dependent: :destroy
  has_many :event_groups, dependent: :destroy
  has_many :historical_facts, dependent: :destroy
  has_many :lotteries, dependent: :destroy
  has_many :monetary_donations, dependent: :destroy
  has_many :stewardships, dependent: :destroy
  has_many :stewards, through: :stewardships, source: :user
  has_many :event_series, dependent: :destroy
  has_many :results_templates, dependent: :destroy

  scope :owned_by, ->(user) { where(created_by: user.id) }
  # Match by a stewardship subquery rather than a join, so results are naturally unique without
  # `distinct`. A `distinct` here breaks when the relation is later ordered by a joined column — e.g.
  # FriendlyId history's `find` orders by friendly_id_slugs.id, which SELECT DISTINCT organizations.*
  # rejects (see #2158).
  scope :authorized_for, lambda { |user|
    where(
      "organizations.created_by = :user_id or organizations.id in (:steward_org_ids)",
      user_id: user.id,
      steward_org_ids: Stewardship.where(user_id: user.id).select(:organization_id),
    )
  }
  scope :visible_or_authorized_for, lambda { |user|
    where(
      "organizations.concealed is not true or organizations.created_by = :user_id " \
      "or organizations.id in (:steward_org_ids)",
      user_id: user.id,
      steward_org_ids: Stewardship.where(user_id: user.id).select(:organization_id),
    )
  }
  scope :with_visible_event_count, lambda {
    left_joins(event_groups: :events)
      .select("organizations.*, COUNT(DISTINCT events) filter (where event_groups.concealed is false) AS event_count")
      .group("organizations.id, event_groups.organization_id")
  }

  alias_attribute :owner_id, :created_by

  validates :name, presence: true
  validates :name, uniqueness: { case_sensitive: false } # rubocop:disable Rails/UniqueValidationWithoutIndex

  def to_s
    slug
  end

  def events
    if event_groups.loaded? && event_groups.all? { |eg| eg.events.loaded? }
      event_groups.flat_map(&:events)
    else
      Event.where(event_group_id: event_groups.ids)
    end
  end

  def owner_full_name
    owner&.full_name
  end

  def owner_email
    owner&.email
  end
end
