module ProjectionAssessments
  class RunnerJob < ApplicationJob
    queue_as :default

    def perform(projection_assessment_run_id)
      projection_assessment_run = ::ProjectionAssessmentRun.find(projection_assessment_run_id)
      ::ProjectionAssessments::Runner.perform!(projection_assessment_run)
    end
  end
end
