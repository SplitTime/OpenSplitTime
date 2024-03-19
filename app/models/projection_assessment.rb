# frozen_string_literal: true

class ProjectionAssessment < ApplicationRecord
  belongs_to :assessment_run, class_name: "ProjectionAssessmentRun", foreign_key: "projection_assessment_run_id"
  belongs_to :effort

  delegate :event, to: :assessment_run, private: true
end
