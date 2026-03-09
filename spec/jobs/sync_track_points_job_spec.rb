require "rails_helper"

RSpec.describe SyncTrackPointsJob do
  include ActiveJob::TestHelper

  # TODO: Remove these adapter overrides once the full migration to Solid Queue is complete.
  before { described_class.queue_adapter = :test }
  after { described_class.queue_adapter = :solid_queue }

  subject(:job) { described_class.perform_later(course.id) }
  let(:course) { courses(:sum_100k_course) }

  it "queues the job" do
    expect { job }.to change(described_class.queue_adapter.enqueued_jobs, :size).by(1)
  end

  it "uses the solid_default queue" do
    expect(SyncTrackPointsJob.new.queue_name).to eq("solid_default")
  end

  # TODO: Change back to `it` once the full migration to Solid Queue is complete
  #   and config.active_job.queue_adapter is set to :solid_queue globally.
  xit "executes perform" do
    expect(::Interactors::SetTrackPoints).to receive(:perform!).with(course)
    perform_enqueued_jobs { job }
  end

  after do
    clear_enqueued_jobs
    clear_performed_jobs
  end
end
