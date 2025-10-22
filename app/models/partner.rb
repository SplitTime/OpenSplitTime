class Partner < ApplicationRecord
  belongs_to :partnerable, polymorphic: true
  scope :with_banners, -> { joins(:banner_attachment).where.not(banner_link: nil) }

  strip_attributes collapse_spaces: true
  has_paper_trail

  has_one_attached :banner do |banner|
    banner.variant :banner_small, resize_to_limit: [364, 45]
    banner.variant :banner_large, resize_to_limit: [728, 90]
  end

  validates :banner,
            content_type: { in: %w[image/png image/jpeg], message: "must be a jpeg or png file" },
            size: { less_than: 1.megabyte, message: "must be less than 1 MB" }

  validates_presence_of :partnerable, :name, :weight

  delegate :organization, to: :partnerable
end
