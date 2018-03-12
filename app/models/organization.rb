# frozen_string_literal: true

class Organization < ApplicationRecord

  include Auditable
  include Concealable
  extend FriendlyId
  strip_attributes collapse_spaces: true
  friendly_id :name, use: [:slugged, :history]
  has_many :event_groups, dependent: :destroy
  has_many :stewardships, dependent: :destroy
  has_many :stewards, through: :stewardships, source: :user

  scope :with_visible_event_count, -> do
    left_joins(event_groups: :events).select('organizations.*, COUNT(DISTINCT events) AS event_count')
        .where(event_groups: {concealed: false}).group('organizations.id, event_groups.organization_id')
  end

  validates_presence_of :name
  validates_uniqueness_of :name, case_sensitive: false

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

  def should_be_concealed?
    !event_groups.visible.present?
  end
end
