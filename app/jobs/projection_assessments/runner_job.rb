module ProjectionAssessments
  class RunnerJob < ApplicationJob
    self.queue_adapter = :solid_queue
    queue_as :solid_default

    def perform(projection_assessment_run_id)
      projection_assessment_run = ::ProjectionAssessmentRun.find(projection_assessment_run_id)
      ::ProjectionAssessments::Runner.perform!(projection_assessment_run)
    end
  end
end
