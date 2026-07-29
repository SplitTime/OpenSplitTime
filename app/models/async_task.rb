class AsyncTask < ApplicationRecord
  STALENESS_THRESHOLD = 30.minutes

  belongs_to :parent, polymorphic: true
  belongs_to :user, optional: true

  enum :status, { in_progress: 0, finished: 1, failed: 2 }

  validates :job_class, presence: true

  scope :active, -> { in_progress.where(created_at: STALENESS_THRESHOLD.ago..) }

  def self.active_for?(parent:, job_class:, context_key: nil)
    active.exists?(parent: parent, job_class: job_class.to_s, context_key: context_key)
  end
end
