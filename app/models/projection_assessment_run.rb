class ProjectionAssessmentRun < ApplicationRecord
  belongs_to :event
  has_many :assessments, class_name: "ProjectionAssessment", dependent: :destroy

  after_update :broadcast_projection_assessment_run

  scope :most_recent_first, -> { reorder(created_at: :desc) }

  enum status: {
    waiting: 0,
    processing: 1,
    finished: 2,
    failed: 3
  }

  delegate :organization, to: :event

  def parsed_errors
    JSON.parse(error_message || "[]")
  end

  def set_elapsed_time!
    return unless persisted? && started_at.present?

    update(elapsed_time: ::Time.current - started_at)
  end

  def start!
    update(started_at: ::Time.current)
  end

  private

  def broadcast_projection_assessment_run
    broadcast_replace_to event,
                         :projection_assessment_runs,
                         partial: "projection_assessment_runs/projection_assessment_run",
                         locals: { organization: self.organization, event: self.event, projection_assessment_run: self }
  end
end
