module ProjectionAssessments
  class RunnerJob < ApplicationJob
    def perform(projection_assessment_run_id)
      projection_assessment_run = ::ProjectionAssessmentRun.find(projection_assessment_run_id)
      ::ProjectionAssessments::Runner.perform!(projection_assessment_run)
    end
  end
end
