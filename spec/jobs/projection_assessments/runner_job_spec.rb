require "rails_helper"

RSpec.describe ProjectionAssessments::RunnerJob do
  include ActiveJob::TestHelper

  subject(:job) { described_class.perform_later(projection_assessment_run.id) }
  let(:projection_assessment_run) { projection_assessment_runs(:projection_assessment_run_one) }

  before { allow(ProjectionAssessments::Runner).to receive(:perform!) }

  it "queues the job" do
    expect { job }.to change(described_class.queue_adapter.enqueued_jobs, :size).by(1)
  end

  it "calls ProjectionAssessments::Runner with the correct arguments" do
    expect(ProjectionAssessments::Runner).to receive(:perform!).with(projection_assessment_run)
    perform_enqueued_jobs { job }
  end

  after do
    clear_enqueued_jobs
    clear_performed_jobs
  end
end
