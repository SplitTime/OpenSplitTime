class ExportJob < ApplicationRecord
  belongs_to :user
  broadcasts_to :user, inserts_by: :prepend

  has_one_attached :file

  scope :most_recent_first, -> { reorder(created_at: :desc) }
  scope :owned_by, ->(user) { where(user: user) }

  enum :status, {
    waiting: 0,
    processing: 1,
    finished: 4,
    failed: 5
  }

  alias_attribute :owner_id, :user_id

  def set_elapsed_time!
    return unless persisted? && started_at.present?

    update_column(:elapsed_time, Time.current - started_at)
  end

  def start!
    update(status: :processing, started_at: ::Time.current)
  end
end
