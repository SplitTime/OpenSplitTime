# frozen_string_literal: true

class Organization < ApplicationRecord
  include Auditable
  include Concealable
  extend FriendlyId
  strip_attributes collapse_spaces: true
  friendly_id :name, use: [:slugged, :history]
  has_paper_trail

  NOT_FOUND_OWNER_ID = -1

  has_many :courses, dependent: :destroy
  has_many :event_groups, dependent: :destroy
  has_many :stewardships, dependent: :destroy
  has_many :stewards, through: :stewardships, source: :user
  has_many :event_series, dependent: :destroy
  has_many :results_templates, dependent: :destroy

  scope :with_visible_event_count, -> do
    left_joins(event_groups: :events).select('organizations.*, COUNT(DISTINCT events) AS event_count')
      .where(event_groups: {concealed: false}).group('organizations.id, event_groups.organization_id')
  end

  alias_attribute :owner_id, :created_by

  validates_presence_of :name
  validates_uniqueness_of :name, case_sensitive: false
  validates_with OwnerExistsValidator

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

  def owner_email
    User.find_by(id: owner_id)&.email
  end

  def owner_email=(email)
    user = User.find_by(email: email)
    self.created_by = user&.id || NOT_FOUND_OWNER_ID
  end
end
