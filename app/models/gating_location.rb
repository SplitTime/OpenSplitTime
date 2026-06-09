class GatingLocation < ApplicationRecord
  belongs_to :event_group
  has_many :gating_location_events, dependent: :destroy
  has_many :events, through: :gating_location_events

  accepts_nested_attributes_for :gating_location_events, allow_destroy: true, reject_if: :all_blank

  validates :name, presence: true
  validates :name, uniqueness: { scope: :event_group_id }
end
