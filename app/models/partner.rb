# frozen_string_literal: true

class Partner < ApplicationRecord
  belongs_to :event_group
  belongs_to :partnerable, polymorphic: true
  scope :with_banners, -> { joins(:banner_attachment).where.not(banner_link: nil) }

  strip_attributes collapse_spaces: true
  has_paper_trail

  has_one_attached :banner do |banner|
    banner.variant :banner_small, resize_to_limit: [364, 45]
    banner.variant :banner_large, resize_to_limit: [728, 90]
  end

  validates :banner,
            content_type: %w[image/png image/jpeg],
            size: {less_than: 500.kilobytes}

  validates_presence_of :event_group, :name, :weight

  delegate :organization, to: :event_group
end
